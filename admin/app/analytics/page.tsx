"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";

type AnalyticsData = {
  overview: {
    total_users: number;
    total_technicians: number;
    total_bookings: number;
    total_revenue: number;
  };
  bookings_by_status: Record<string, number>;
  revenue_by_period: Array<{
    period: string;
    amount: number;
  }>;
  top_technicians: Array<{
    id: string;
    name: string;
    rating: number;
    jobs_completed: number;
    earnings: number;
  }>;
  low_rated_technicians: Array<{
    id: string;
    name: string;
    rating: number;
    total_jobs: number;
  }>;
};

export default function AnalyticsDashboard() {
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState("month"); // day, week, month, year

  useEffect(() => {
    fetchAnalytics();
  }, [period]);

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      // TODO: Replace with actual API endpoint
      // const response = await api.get(`/api/admin/analytics?period=${period}`);
      // setAnalytics(response.data);

      // Mock data for now
      setAnalytics({
        overview: {
          total_users: 342,
          total_technicians: 87,
          total_bookings: 1203,
          total_revenue: 45320.5,
        },
        bookings_by_status: {
          completed: 890,
          in_progress: 156,
          pending: 127,
          cancelled: 30,
        },
        revenue_by_period: [
          { period: "Week 1", amount: 8500 },
          { period: "Week 2", amount: 9200 },
          { period: "Week 3", amount: 11200 },
          { period: "Week 4", amount: 16420.5 },
        ],
        top_technicians: [
          { id: "1", name: "John Doe", rating: 4.8, jobs_completed: 256, earnings: 12500 },
          { id: "2", name: "Jane Smith", rating: 4.7, jobs_completed: 198, earnings: 10200 },
          { id: "3", name: "Mike Johnson", rating: 4.6, jobs_completed: 142, earnings: 7800 },
        ],
        low_rated_technicians: [
          { id: "10", name: "Poor Performer", rating: 2.1, total_jobs: 45 },
          { id: "11", name: "Below Average", rating: 2.8, total_jobs: 32 },
        ],
      });
    } catch (error) {
      console.error("Error fetching analytics:", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 p-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center text-gray-500">Loading...</div>
        </div>
      </div>
    );
  }

  if (!analytics) {
    return (
      <div className="min-h-screen bg-gray-50 p-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center text-gray-500">Failed to load analytics</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Analytics & Reports</h1>
            <p className="text-gray-600 mt-2">Platform performance and insights</p>
          </div>

          {/* Period Selector */}
          <div className="flex gap-2">
            {["day", "week", "month", "year"].map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  period === p
                    ? "bg-blue-600 text-white"
                    : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                }`}
              >
                {p.charAt(0).toUpperCase() + p.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* Overview Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <p className="text-sm font-medium text-gray-600 uppercase">Total Users</p>
            <p className="text-3xl font-bold text-gray-900 mt-2">
              {analytics.overview.total_users}
            </p>
            <p className="text-sm text-gray-600 mt-2">+12% from last period</p>
          </div>

          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <p className="text-sm font-medium text-gray-600 uppercase">Technicians</p>
            <p className="text-3xl font-bold text-gray-900 mt-2">
              {analytics.overview.total_technicians}
            </p>
            <p className="text-sm text-gray-600 mt-2">+5% from last period</p>
          </div>

          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <p className="text-sm font-medium text-gray-600 uppercase">Bookings</p>
            <p className="text-3xl font-bold text-gray-900 mt-2">
              {analytics.overview.total_bookings}
            </p>
            <p className="text-sm text-gray-600 mt-2">
              {((analytics.bookings_by_status.completed / analytics.overview.total_bookings) *
                100).toFixed(1)}
              % completion rate
            </p>
          </div>

          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <p className="text-sm font-medium text-gray-600 uppercase">Revenue</p>
            <p className="text-3xl font-bold text-gray-900 mt-2">
              ${analytics.overview.total_revenue.toFixed(0)}
            </p>
            <p className="text-sm text-gray-600 mt-2">+23% from last period</p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Bookings Status Chart */}
          <div className="lg:col-span-2 bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Bookings by Status</h2>
            <div className="space-y-4">
              {Object.entries(analytics.bookings_by_status).map(([status, count]) => (
                <div key={status}>
                  <div className="flex justify-between items-center mb-2">
                    <p className="text-sm font-medium text-gray-700 capitalize">
                      {status}
                    </p>
                    <p className="text-sm font-bold text-gray-900">{count}</p>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        status === "completed"
                          ? "bg-green-500"
                          : status === "in_progress"
                          ? "bg-blue-500"
                          : status === "pending"
                          ? "bg-yellow-500"
                          : "bg-red-500"
                      }`}
                      style={{
                        width: `${(count / analytics.overview.total_bookings) * 100}%`,
                      }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Revenue Trend */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Revenue Trend</h2>
            <div className="space-y-3">
              {analytics.revenue_by_period.map((data) => (
                <div key={data.period}>
                  <p className="text-sm text-gray-600">{data.period}</p>
                  <p className="text-lg font-bold text-gray-900">
                    ${data.amount.toFixed(0)}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Top Technicians */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Top Technicians</h2>
            <div className="space-y-4">
              {analytics.top_technicians.map((tech, idx) => (
                <div key={tech.id} className="flex items-center justify-between pb-4 border-b border-gray-200 last:border-0">
                  <div>
                    <p className="font-medium text-gray-900">
                      #{idx + 1} {tech.name}
                    </p>
                    <p className="text-sm text-gray-600">
                      ⭐ {tech.rating} • {tech.jobs_completed} jobs
                    </p>
                  </div>
                  <p className="font-bold text-green-600">${tech.earnings.toFixed(0)}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Low Rated Technicians */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="text-lg font-bold text-gray-900 mb-4">
              Low-Rated Technicians
            </h2>
            <p className="text-sm text-gray-600 mb-4">
              Technicians below 3.0 rating - consider outreach or suspension
            </p>
            <div className="space-y-4">
              {analytics.low_rated_technicians.length === 0 ? (
                <p className="text-sm text-gray-600 text-center py-8">
                  No low-rated technicians 🎉
                </p>
              ) : (
                analytics.low_rated_technicians.map((tech) => (
                  <div key={tech.id} className="p-3 bg-red-50 rounded-lg border border-red-200">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">{tech.name}</p>
                        <p className="text-sm text-red-600">
                          ⭐ {tech.rating} ({tech.total_jobs} jobs)
                        </p>
                      </div>
                      <button className="text-sm px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700">
                        Review
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
