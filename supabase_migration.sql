-- Supabase Migration SQL for Meeting Audio Storage
-- This file creates the necessary tables, storage buckets, and policies
-- for storing meeting audio files in Supabase
-- 
-- Instructions:
-- 1. Copy this entire file content
-- 2. Go to your Supabase Dashboard
-- 3. Navigate to SQL Editor
-- 4. Create a new query
-- 5. Paste this content and run it

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create audio_files table to track metadata
CREATE TABLE IF NOT EXISTS public.audio_files (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id TEXT NOT NULL,
    meeting_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    content_type TEXT NOT NULL,
    duration INTEGER, -- Duration in seconds
    transcription_status TEXT DEFAULT 'pending', -- pending, processing, completed, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Indexes for better query performance
    CONSTRAINT unique_meeting_audio UNIQUE(meeting_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON public.audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_meeting_id ON public.audio_files(meeting_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_created_at ON public.audio_files(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audio_files_transcription_status ON public.audio_files(transcription_status);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS set_audio_files_updated_at ON public.audio_files;
CREATE TRIGGER set_audio_files_updated_at
    BEFORE UPDATE ON public.audio_files
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE public.audio_files ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for audio_files table

-- Policy: Users can view their own audio files
CREATE POLICY "Users can view own audio files" ON public.audio_files
    FOR SELECT
    USING (auth.uid()::text = user_id OR auth.role() = 'service_role');

-- Policy: Users can insert their own audio files
CREATE POLICY "Users can insert own audio files" ON public.audio_files
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

-- Policy: Users can update their own audio files
CREATE POLICY "Users can update own audio files" ON public.audio_files
    FOR UPDATE
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

-- Policy: Users can delete their own audio files
CREATE POLICY "Users can delete own audio files" ON public.audio_files
    FOR DELETE
    USING (auth.uid()::text = user_id);

-- Create storage bucket for audio files
-- Note: This needs to be done through Supabase Dashboard or using Supabase Management API
-- as storage buckets cannot be created via SQL

-- After creating the bucket named 'meeting-audio' in the dashboard, 
-- run these commands to set up storage policies:

-- The following SQL comments show the storage policies you need to set up
-- in the Supabase Dashboard under Storage > Policies:

/*
Storage Bucket Configuration:
1. Create a bucket named: meeting-audio
2. Set the following policies:

-- Policy: Authenticated users can upload audio files
Name: "Authenticated users can upload"
Allowed operations: INSERT
Target roles: authenticated
Policy definition:
bucket_id = 'meeting-audio' AND auth.role() = 'authenticated'

-- Policy: Users can view their own audio files
Name: "Users can view own files"
Allowed operations: SELECT
Target roles: authenticated, anon
Policy definition:
bucket_id = 'meeting-audio' AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy: Users can update their own audio files
Name: "Users can update own files"
Allowed operations: UPDATE
Target roles: authenticated
Policy definition:
bucket_id = 'meeting-audio' AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy: Users can delete their own audio files
Name: "Users can delete own files"
Allowed operations: DELETE
Target roles: authenticated
Policy definition:
bucket_id = 'meeting-audio' AND (storage.foldername(name))[1] = auth.uid()::text
*/

-- Create a function to get signed URL for audio files
CREATE OR REPLACE FUNCTION public.get_audio_signed_url(
    p_file_path TEXT,
    p_expires_in INTEGER DEFAULT 3600
)
RETURNS TEXT AS $$
DECLARE
    v_signed_url TEXT;
BEGIN
    -- This is a placeholder function
    -- Actual signed URL generation should be done through Supabase client SDK
    -- This function demonstrates the expected interface
    RETURN 'Use Supabase client SDK to generate signed URLs';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to clean up old audio files (optional)
CREATE OR REPLACE FUNCTION public.cleanup_old_audio_files()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Delete audio files older than 30 days that have been transcribed
    DELETE FROM public.audio_files
    WHERE created_at < NOW() - INTERVAL '30 days'
    AND transcription_status = 'completed';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for audio file statistics (optional)
CREATE OR REPLACE VIEW public.audio_file_stats AS
SELECT 
    user_id,
    COUNT(*) as total_files,
    SUM(file_size) as total_size_bytes,
    SUM(duration) as total_duration_seconds,
    COUNT(CASE WHEN transcription_status = 'completed' THEN 1 END) as transcribed_count,
    COUNT(CASE WHEN transcription_status = 'pending' THEN 1 END) as pending_count,
    COUNT(CASE WHEN transcription_status = 'failed' THEN 1 END) as failed_count,
    MAX(created_at) as last_upload_at
FROM public.audio_files
GROUP BY user_id;

-- Grant access to the view
GRANT SELECT ON public.audio_file_stats TO authenticated;

-- Sample data for testing (optional - remove in production)
-- INSERT INTO public.audio_files (user_id, meeting_id, file_name, file_path, file_size, content_type)
-- VALUES 
-- ('test-user-1', 'meeting-1', 'test-audio.mp3', 'test-user-1/meeting-1/test-audio.mp3', 1024000, 'audio/mpeg'),
-- ('test-user-1', 'meeting-2', 'test-audio-2.wav', 'test-user-1/meeting-2/test-audio-2.wav', 2048000, 'audio/wav');

-- Useful queries for monitoring and maintenance

-- Query to check storage usage by user
/*
SELECT 
    user_id,
    COUNT(*) as file_count,
    pg_size_pretty(SUM(file_size)::BIGINT) as total_size,
    MAX(created_at) as last_upload
FROM public.audio_files
GROUP BY user_id
ORDER BY SUM(file_size) DESC;
*/

-- Query to find failed transcriptions
/*
SELECT 
    id,
    meeting_id,
    file_name,
    created_at,
    metadata->>'error' as error_message
FROM public.audio_files
WHERE transcription_status = 'failed'
ORDER BY created_at DESC;
*/

-- Query to find orphaned files (files without corresponding meetings)
/*
SELECT 
    id,
    meeting_id,
    file_name,
    file_path,
    created_at
FROM public.audio_files af
WHERE NOT EXISTS (
    -- This assumes you have a meetings table
    -- Adjust based on your actual schema
    SELECT 1 FROM public.meetings m 
    WHERE m.id = af.meeting_id
);
*/

COMMENT ON TABLE public.audio_files IS 'Stores metadata for audio files uploaded to Supabase Storage';
COMMENT ON COLUMN public.audio_files.user_id IS 'User ID from Supabase Auth';
COMMENT ON COLUMN public.audio_files.meeting_id IS 'Unique identifier for the meeting';
COMMENT ON COLUMN public.audio_files.file_path IS 'Path in Supabase Storage bucket';
COMMENT ON COLUMN public.audio_files.transcription_status IS 'Status of audio transcription: pending, processing, completed, failed';
COMMENT ON COLUMN public.audio_files.metadata IS 'Additional metadata in JSON format';