-- Supabase Data Migration SQL for Meeting App
-- This file creates all necessary tables for storing meeting data
-- including meetings, notes, transcriptions, and summaries
--
-- Instructions:
-- 1. Copy this entire file content
-- 2. Go to your Supabase Dashboard
-- 3. Navigate to SQL Editor
-- 4. Create a new query
-- 5. Paste this content and run it

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- MEETINGS TABLE
-- =====================================================
-- Main table for storing meeting records
CREATE TABLE IF NOT EXISTS public.meetings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    legacy_id TEXT UNIQUE, -- For migrating existing numeric IDs
    title TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration TEXT NOT NULL, -- Format: "MM:SS" or "HH:MM:SS"
    duration_seconds INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN duration ~ '^\d{2}:\d{2}$' THEN 
                EXTRACT(MINUTE FROM duration::INTERVAL) * 60 + 
                EXTRACT(SECOND FROM duration::INTERVAL)
            WHEN duration ~ '^\d{2}:\d{2}:\d{2}$' THEN 
                EXTRACT(HOUR FROM duration::INTERVAL) * 3600 + 
                EXTRACT(MINUTE FROM duration::INTERVAL) * 60 + 
                EXTRACT(SECOND FROM duration::INTERVAL)
            ELSE 0
        END
    ) STORED,
    participants TEXT DEFAULT '1',
    audio_path TEXT, -- Local path reference
    audio_file_id UUID, -- Reference to audio_files table
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete support
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Indexes
    INDEX idx_meetings_user_id (user_id),
    INDEX idx_meetings_date (date DESC),
    INDEX idx_meetings_sync_status (sync_status),
    INDEX idx_meetings_deleted_at (deleted_at)
);

-- =====================================================
-- MEETING NOTES TABLE
-- =====================================================
-- Time-stamped notes taken during recording
CREATE TABLE IF NOT EXISTS public.meeting_notes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
    time TEXT NOT NULL, -- Timestamp in recording (MM:SS format)
    time_seconds INTEGER GENERATED ALWAYS AS (
        EXTRACT(MINUTE FROM time::INTERVAL) * 60 + 
        EXTRACT(SECOND FROM time::INTERVAL)
    ) STORED,
    note TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Indexes
    INDEX idx_meeting_notes_meeting_id (meeting_id),
    INDEX idx_meeting_notes_time (time_seconds)
);

-- =====================================================
-- MEETING TRANSCRIPTIONS TABLE
-- =====================================================
-- Full transcription data with segments
CREATE TABLE IF NOT EXISTS public.meeting_transcriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
    full_text TEXT,
    formatted_text TEXT, -- With speaker labels
    language TEXT DEFAULT 'zh-CN',
    transcription_service TEXT, -- volcano, whisper, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Ensure one transcription per meeting
    CONSTRAINT unique_meeting_transcription UNIQUE(meeting_id)
);

-- =====================================================
-- TRANSCRIPTION SEGMENTS TABLE
-- =====================================================
-- Individual segments with speaker information
CREATE TABLE IF NOT EXISTS public.transcription_segments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    transcription_id UUID NOT NULL REFERENCES public.meeting_transcriptions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    start_time REAL NOT NULL, -- in seconds
    end_time REAL NOT NULL,
    speaker_id TEXT,
    confidence REAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Indexes
    INDEX idx_segments_transcription_id (transcription_id),
    INDEX idx_segments_time (start_time, end_time)
);

-- =====================================================
-- MEETING SUMMARIES TABLE
-- =====================================================
-- AI-generated summaries with key points and action items
CREATE TABLE IF NOT EXISTS public.meeting_summaries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
    summary_text TEXT,
    key_points TEXT[], -- Array of key points
    action_items TEXT[], -- Array of action items
    ai_model TEXT, -- gpt-3.5-turbo, doubao, etc.
    custom_prompt TEXT, -- If custom prompt was used
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Ensure one summary per meeting
    CONSTRAINT unique_meeting_summary UNIQUE(meeting_id)
);

-- =====================================================
-- SYNC METADATA TABLE
-- =====================================================
-- Track sync status and conflicts
CREATE TABLE IF NOT EXISTS public.sync_metadata (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    device_id TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Ensure one sync metadata per user-device
    CONSTRAINT unique_user_device UNIQUE(user_id, device_id)
);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to all tables with updated_at
CREATE TRIGGER set_meetings_updated_at
    BEFORE UPDATE ON public.meetings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_transcriptions_updated_at
    BEFORE UPDATE ON public.meeting_transcriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_summaries_updated_at
    BEFORE UPDATE ON public.meeting_summaries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_sync_metadata_updated_at
    BEFORE UPDATE ON public.sync_metadata
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_transcriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transcription_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_metadata ENABLE ROW LEVEL SECURITY;

-- Meetings policies
CREATE POLICY "Users can view own meetings" ON public.meetings
    FOR SELECT
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert own meetings" ON public.meetings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meetings" ON public.meetings
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own meetings" ON public.meetings
    FOR DELETE
    USING (auth.uid() = user_id);

-- Meeting notes policies
CREATE POLICY "Users can view own meeting notes" ON public.meeting_notes
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE meetings.id = meeting_notes.meeting_id 
        AND meetings.user_id = auth.uid()
        AND meetings.deleted_at IS NULL
    ));

CREATE POLICY "Users can insert own meeting notes" ON public.meeting_notes
    FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE meetings.id = meeting_notes.meeting_id 
        AND meetings.user_id = auth.uid()
    ));

CREATE POLICY "Users can update own meeting notes" ON public.meeting_notes
    FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE meetings.id = meeting_notes.meeting_id 
        AND meetings.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete own meeting notes" ON public.meeting_notes
    FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE meetings.id = meeting_notes.meeting_id 
        AND meetings.user_id = auth.uid()
    ));

-- Similar policies for transcriptions
CREATE POLICY "Users can view own transcriptions" ON public.meeting_transcriptions
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE meetings.id = meeting_transcriptions.meeting_id 
        AND meetings.user_id = auth.uid()
        AND meetings.deleted_at IS NULL
    ));

-- Similar policies for transcription segments
CREATE POLICY "Users can view own segments" ON public.transcription_segments
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.meeting_transcriptions t
        JOIN public.meetings m ON m.id = t.meeting_id
        WHERE t.id = transcription_segments.transcription_id 
        AND m.user_id = auth.uid()
        AND m.deleted_at IS NULL
    ));

-- Similar policies for summaries
CREATE POLICY "Users can view own summaries" ON public.meeting_summaries
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE meetings.id = meeting_summaries.meeting_id 
        AND meetings.user_id = auth.uid()
        AND meetings.deleted_at IS NULL
    ));

-- Sync metadata policies
CREATE POLICY "Users can manage own sync metadata" ON public.sync_metadata
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get all meeting data (for sync)
CREATE OR REPLACE FUNCTION public.get_full_meeting_data(p_meeting_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'meeting', row_to_json(m.*),
        'notes', COALESCE(
            (SELECT jsonb_agg(row_to_json(n.*))
             FROM public.meeting_notes n
             WHERE n.meeting_id = m.id), 
            '[]'::jsonb
        ),
        'transcription', 
            (SELECT row_to_json(t.*)
             FROM public.meeting_transcriptions t
             WHERE t.meeting_id = m.id),
        'segments', COALESCE(
            (SELECT jsonb_agg(row_to_json(s.*))
             FROM public.transcription_segments s
             JOIN public.meeting_transcriptions t ON t.id = s.transcription_id
             WHERE t.meeting_id = m.id
             ORDER BY s.start_time), 
            '[]'::jsonb
        ),
        'summary', 
            (SELECT row_to_json(su.*)
             FROM public.meeting_summaries su
             WHERE su.meeting_id = m.id)
    ) INTO v_result
    FROM public.meetings m
    WHERE m.id = p_meeting_id;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for hard delete (removes all related data)
CREATE OR REPLACE FUNCTION public.hard_delete_meeting(p_meeting_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user owns the meeting
    IF NOT EXISTS (
        SELECT 1 FROM public.meetings 
        WHERE id = p_meeting_id 
        AND user_id = auth.uid()
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Delete will cascade to all related tables due to ON DELETE CASCADE
    DELETE FROM public.meetings WHERE id = p_meeting_id;
    
    -- Also delete from audio_files if linked
    DELETE FROM public.audio_files 
    WHERE meeting_id = p_meeting_id::TEXT;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VIEWS
-- =====================================================

-- Create a view for meeting list with summary info
CREATE OR REPLACE VIEW public.meetings_with_summary AS
SELECT 
    m.*,
    mt.full_text IS NOT NULL AS has_transcription,
    ms.summary_text IS NOT NULL AS has_summary,
    array_length(ms.key_points, 1) AS key_points_count,
    array_length(ms.action_items, 1) AS action_items_count
FROM public.meetings m
LEFT JOIN public.meeting_transcriptions mt ON mt.meeting_id = m.id
LEFT JOIN public.meeting_summaries ms ON ms.meeting_id = m.id
WHERE m.deleted_at IS NULL;

-- Grant access to the view
GRANT SELECT ON public.meetings_with_summary TO authenticated;

-- =====================================================
-- INITIAL DATA / EXAMPLES
-- =====================================================

-- Add comments for documentation
COMMENT ON TABLE public.meetings IS 'Main table storing meeting records';
COMMENT ON TABLE public.meeting_notes IS 'Time-stamped notes taken during meeting recording';
COMMENT ON TABLE public.meeting_transcriptions IS 'Full transcription text and metadata';
COMMENT ON TABLE public.transcription_segments IS 'Individual transcription segments with timing and speaker info';
COMMENT ON TABLE public.meeting_summaries IS 'AI-generated summaries with key points and action items';
COMMENT ON TABLE public.sync_metadata IS 'Tracks sync status between local and cloud storage';

COMMENT ON COLUMN public.meetings.legacy_id IS 'Used for migrating existing numeric IDs from local storage';
COMMENT ON COLUMN public.meetings.sync_status IS 'Sync status: pending (needs sync), synced (up to date), conflict (needs resolution)';
COMMENT ON COLUMN public.meetings.deleted_at IS 'Soft delete timestamp - if set, meeting is considered deleted but data retained';

-- =====================================================
-- MIGRATION HELPERS
-- =====================================================

-- Function to migrate legacy meeting data
CREATE OR REPLACE FUNCTION public.migrate_legacy_meeting(
    p_legacy_id TEXT,
    p_title TEXT,
    p_date TIMESTAMP WITH TIME ZONE,
    p_duration TEXT,
    p_participants TEXT DEFAULT '1',
    p_audio_path TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_meeting_id UUID;
BEGIN
    INSERT INTO public.meetings (
        user_id,
        legacy_id,
        title,
        date,
        duration,
        participants,
        audio_path,
        sync_status
    ) VALUES (
        auth.uid(),
        p_legacy_id,
        p_title,
        p_date,
        p_duration,
        p_participants,
        p_audio_path,
        'synced'
    )
    ON CONFLICT (legacy_id) 
    DO UPDATE SET
        title = EXCLUDED.title,
        date = EXCLUDED.date,
        duration = EXCLUDED.duration,
        participants = EXCLUDED.participants,
        audio_path = EXCLUDED.audio_path,
        sync_status = 'synced',
        updated_at = NOW()
    RETURNING id INTO v_meeting_id;
    
    RETURN v_meeting_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;