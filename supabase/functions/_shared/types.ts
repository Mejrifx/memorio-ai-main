// Shared TypeScript types for Memorio Edge Functions

export interface User {
  id: string;
  email: string;
  role: 'admin' | 'director' | 'family' | 'editor' | 'support' | 'qc';
  org_id?: string;
  status: 'invited' | 'active' | 'suspended' | 'archived';
  metadata: {
    name: string;
    phone?: string;
    [key: string]: any;
  };
  created_at: string;
  updated_at: string;
  last_login_at?: string;
}

export interface Case {
  id: string;
  org_id: string;
  deceased_name: string;
  created_by: string;
  assigned_family_user_id?: string;
  status: 'created' | 'waiting_on_family' | 'intake_in_progress' | 'submitted' | 'in_production' | 'awaiting_review' | 'revision_requested' | 'delivered' | 'closed';
  first_submission_at?: string;  // When SLA clock starts
  sla_hours_elapsed?: number;    // Hours since submission
  sla_state?: 'green' | 'yellow' | 'orange' | 'red' | 'on_time' | 'warning' | 'breach';
  metadata?: {
    service_date?: string;
    service_location?: string;
    [key: string]: any;
  };
  created_at: string;
  updated_at: string;
}

export interface CaseNote {
  id: string;
  case_id: string;
  author_user_id: string;
  note_type: 'general' | 'support' | 'revision' | 'internal';
  content: string;
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
}

export interface InviteDirectorRequest {
  email: string;
  name: string;
  org_id: string;
  phone?: string;
}

export interface InviteFamilyRequest {
  email: string;
  name: string;
  case_id: string;
  phone?: string;
}

export interface CreateCaseRequest {
  deceased_name: string;
  service_date?: string;
  service_location?: string;
  metadata?: object;
}

export interface VideoSubmission {
  id: string;
  case_id: string;
  editor_user_id: string;
  video_url: string;
  thumbnail_url?: string;
  duration_seconds?: number;
  file_size_bytes: number;
  mime_type: string;
  editor_notes?: string;
  submitted_at: string;
  qc_reviewer_id?: string;
  qc_status: 'pending' | 'in_review' | 'approved' | 'revision_requested' | 'rejected';
  qc_notes?: string;
  qc_reviewed_at?: string;
  revision_number: number;
  previous_submission_id?: string;
  created_at: string;
  updated_at: string;
}

export interface ObituaryContent {
  id: string;
  case_id: string;
  content_html: string;
  content_plain: string;
  generated_at: string;
  generated_by: string;
  approved_by?: string;
  approved_at?: string;
  version: number;
  created_at: string;
  updated_at: string;
}

export interface InviteQCRequest {
  email: string;
  name: string;
  phone?: string;
  // No org_id - QC users are global
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

