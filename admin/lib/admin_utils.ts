// Admin utilities for data processing and analytics

export type DashboardStats = {
  totalBookings: number;
  pendingBookings: number;
  completedBookings: number;
  totalRevenue: number;
  averageRating: number;
  activeUsers: number;
  activeTechnicians: number;
  bookingsByStatus: Record<string, number>;
};

export type Payment = {
  id: string;
  booking_id: string;
  amount: number;
  method: string;
  status: string;
  transaction_id?: string;
  paid_at?: string;
};

export type AdminUser = {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role: string;
  is_active: boolean;
  created_at: string;
  avatar_url?: string;
};

export type Technician = {
  id: string;
  user_id: string;
  bio?: string;
  rating: number;
  total_jobs: number;
  is_verified: boolean;
  is_available: boolean;
  current_lat?: number;
  current_lng?: number;
};

export function calculateDashboardStats(
  bookings: any[],
  payments: Payment[],
  users: AdminUser[]
): DashboardStats {
  const bookingsByStatus = bookings.reduce(
    (acc, booking) => {
      acc[booking.status] = (acc[booking.status] || 0) + 1;
      return acc;
    },
    {} as Record<string, number>
  );

  const totalRevenue = payments
    .filter((p) => p.status === "completed")
    .reduce((sum, p) => sum + p.amount, 0);

  const completedBookings = bookings.filter((b) => b.status === "completed").length;
  const averageRating =
    completedBookings > 0
      ? bookings
          .filter((b) => b.status === "completed" && b.rating)
          .reduce((sum, b) => sum + b.rating, 0) / completedBookings
      : 0;

  return {
    totalBookings: bookings.length,
    pendingBookings: bookingsByStatus["pending"] || 0,
    completedBookings,
    totalRevenue,
    averageRating: Math.round(averageRating * 10) / 10,
    activeUsers: users.filter((u) => u.role === "customer" && u.is_active).length,
    activeTechnicians: users.filter((u) => u.role === "technician" && u.is_active).length,
    bookingsByStatus,
  };
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
}

export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function formatDateTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
