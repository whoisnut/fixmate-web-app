import axios, { AxiosError } from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
});

api.interceptors.request.use((config) => {
  // Prepend new versioned API prefix
  if (config.url) {
    // If it already has /api/, replace it with /api/v1.0.0/
    if (config.url.startsWith('/api/')) {
      config.url = config.url.replace('/api/', '/api/v1.0.0/');
    } else if (!config.url.startsWith('http')) {
      // Otherwise just prepend it
      config.url = `/api/v1.0.0${config.url.startsWith('/') ? '' : '/'}${config.url}`;
    }
  }

  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
      console.log(`Sending request to ${config.url} with token`);
    } else {
      console.warn(`Sending request to ${config.url} without token`);
    }
  }
  return config;
});

api.interceptors.response.use(
  (response) => {
    // Handle new backend response format: { data: { ... }, response_status: "success", ... }
    if (
      response.data &&
      response.data.data !== undefined &&
      response.data.response_status !== undefined
    ) {
      return { ...response, data: response.data.data };
    }
    return response;
  },
  (error: AxiosError) => {
    if (error.response?.status === 401 && typeof window !== 'undefined') {
      localStorage.removeItem('token');
      localStorage.removeItem('admin_user');
    }
    return Promise.reject(error);
  },
);

export const adminApi = {
  // Auth
  logout: () => api.post('/auth/logout'),

  // Users
  getUsers: () => api.get('/admin/users'),
  suspendUser: (userId: string) => api.post(`/admin/users/${userId}/suspend`),
  unsuspendUser: (userId: string) =>
    api.post(`/admin/users/${userId}/unsuspend`),

  // Technicians
  getTechnicians: () => api.get('/admin/technicians'),
  verifyTechnician: (technicianId: string) =>
    api.post(`/admin/technicians/${technicianId}/verify`),
  rejectTechnician: (technicianId: string, reason: string) =>
    api.post(`/admin/technicians/${technicianId}/reject`, { reason }),
  suspendTechnician: (technicianId: string) =>
    api.post(`/admin/technicians/${technicianId}/suspend`),
  getLowRatedTechnicians: (minRating = 3.0) =>
    api.get(`/admin/technicians/low-rated?min_rating=${minRating}`),
  getTechnicianStats: (technicianId: string) =>
    api.get(`/admin/technicians/${technicianId}/stats`),

  // Bookings (admin can see all via GET /api/bookings as admin role)
  getBookings: () => api.get('/bookings'),
  updateBookingStatus: (bookingId: string, status: string) =>
    api.put(`/bookings/${bookingId}`, { status }),

  // Payouts
  getPayouts: (status?: string) =>
    api.get(status ? `/payouts?status=${status}` : '/payouts'),
  approvePayout: (payoutId: string) => api.post(`/payouts/${payoutId}/approve`),
  rejectPayout: (payoutId: string, reason: string) =>
    api.post(`/payouts/${payoutId}/reject`, { reason }),
  completePayout: (payoutId: string) =>
    api.post(`/payouts/${payoutId}/complete`),

  // Analytics
  getAnalyticsOverview: (days = 30) =>
    api.get(`/admin/analytics/overview?days=${days}`),
  getBookingAnalytics: (days = 30) =>
    api.get(`/admin/analytics/bookings?days=${days}`),
  getRevenueAnalytics: (days = 30) =>
    api.get(`/admin/analytics/revenue?days=${days}`),
  getTopTechnicians: (limit = 10) =>
    api.get(`/admin/top-technicians?limit=${limit}`),

  // Reviews
  getReviews: () => api.get('/admin/reviews'),
  deleteReview: (reviewId: string) => api.delete(`/admin/reviews/${reviewId}`),

  // App Credentials
  authenticateApp: (appName: string, apiKey: string) =>
    api.post('/auth/apps/authenticate', { app_name: appName, api_key: apiKey }),
  listAppCredentials: () => api.get('/auth/apps'),
  getAppCredential: (appName: string) => api.get(`/auth/apps/${appName}`),
  regenerateAppCredential: (appName: string) =>
    api.post(`/auth/apps/${appName}/regenerate`),
  toggleAppCredential: (appName: string) =>
    api.put(`/auth/apps/${appName}/toggle`),
};

export default api;
