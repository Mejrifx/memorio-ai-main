// Shared TypeScript types for Memorio Edge Functions

export interface User {
  id: string;
  email: string;
  role: 'admin' | 'director' | 'family' | 'editor' | 'support';
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
  status: 'created' | 'waiting_on_family' | 'intake_in_progress' | 'submitted' | 'in_production' | 'awaiting_review' | 'delivered' | 'closed';
  sla_start_at?: string;
  sla_state?: 'on_time' | 'warning' | 'breach';
  metadata?: {
    service_date?: string;
    service_location?: string;
    [key: string]: any;
  };
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

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

