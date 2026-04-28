import axios, { AxiosError } from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Handle unauthorized - clear token and redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('admin_user');
      window.location.reload();
    }
    return Promise.reject(error);
  }
);

// Admin utility methods
export const adminApi = {
  // Refresh token
  refreshToken: (refreshToken: string) =>
    api.post('/api/auth/refresh', { refresh_token: refreshToken }),

  // Logout
  logout: () => api.post('/api/auth/logout'),

  // Get all users (admin only)
  getUsers: () => api.get('/api/admin/users'),

  // Get all payments (admin only)
  getPayments: () => api.get('/api/payments/all'),

  // Update payment status (admin only)
  updatePaymentStatus: (paymentId: string, status: string) =>
    api.put(`/api/payments/${paymentId}`, { status }),

  // Get analytics (admin only)
  getAnalytics: () => api.get('/api/admin/analytics'),

  // Get technician stats (admin only)
  getTechnicianStats: () => api.get('/api/admin/technicians/stats'),

  // Verify technician
  verifyTechnician: (technicianId: string) =>
    api.post(`/api/admin/technicians/${technicianId}/verify`),

  // Suspend user
  suspendUser: (userId: string) =>
    api.post(`/api/admin/users/${userId}/suspend`),

  // Unsuspend user
  unsuspendUser: (userId: string) =>
    api.post(`/api/admin/users/${userId}/unsuspend`),
};

export default api;
