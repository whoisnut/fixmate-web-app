import axios, { AxiosError } from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
});

api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401 && typeof window !== 'undefined') {
      localStorage.removeItem('token');
      localStorage.removeItem('admin_user');
    }
    return Promise.reject(error);
  }
);

export const adminApi = {
  // Auth
  logout: () => api.post('/api/auth/logout'),

  // Users
  getUsers: () => api.get('/api/admin/users'),
  suspendUser: (userId: string) => api.post(`/api/admin/users/${userId}/suspend`),
  unsuspendUser: (userId: string) => api.post(`/api/admin/users/${userId}/unsuspend`),

  // Technicians
  getTechnicians: () => api.get('/api/admin/technicians'),
  verifyTechnician: (technicianId: string) => api.post(`/api/admin/technicians/${technicianId}/verify`),
  rejectTechnician: (technicianId: string, reason: string) =>
    api.post(`/api/admin/technicians/${technicianId}/reject`, { reason }),
  suspendTechnician: (technicianId: string) => api.post(`/api/admin/technicians/${technicianId}/suspend`),
  getLowRatedTechnicians: (minRating = 3.0) =>
    api.get(`/api/admin/technicians/low-rated?min_rating=${minRating}`),
  getTechnicianStats: (technicianId: string) =>
    api.get(`/api/admin/technicians/${technicianId}/stats`),

  // Bookings (admin can see all via GET /api/bookings as admin role)
  getBookings: () => api.get('/api/bookings'),
  updateBookingStatus: (bookingId: string, status: string) =>
    api.put(`/api/bookings/${bookingId}`, { status }),

  // Payouts
  getPayouts: (status?: string) =>
    api.get(status ? `/api/payouts?status=${status}` : '/api/payouts'),
  approvePayout: (payoutId: string) => api.post(`/api/payouts/${payoutId}/approve`),
  rejectPayout: (payoutId: string, reason: string) =>
    api.post(`/api/payouts/${payoutId}/reject`, { reason }),
  completePayout: (payoutId: string) => api.post(`/api/payouts/${payoutId}/complete`),

  // Analytics
  getAnalyticsOverview: (days = 30) => api.get(`/api/admin/analytics/overview?days=${days}`),
  getBookingAnalytics: (days = 30) => api.get(`/api/admin/analytics/bookings?days=${days}`),
  getRevenueAnalytics: (days = 30) => api.get(`/api/admin/analytics/revenue?days=${days}`),
  getTopTechnicians: (limit = 10) => api.get(`/api/admin/top-technicians?limit=${limit}`),

  // Reviews
  getReviews: () => api.get('/api/admin/reviews'),
  deleteReview: (reviewId: string) => api.delete(`/api/admin/reviews/${reviewId}`),
};

export default api;
