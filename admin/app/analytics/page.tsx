"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import api, { adminApi } from "@/lib/api";
import { getStoredToken } from "@/lib/auth";

type Overview = {
  total_users: number;
  total_technicians: number;
  total_bookings: number;
  total_revenue: number;
};

type TopTechnician = {
  id: string;
  name: string;
  rating: number;
  jobs_completed: number;
  earnings: number;
};

type LowRatedTechnician = {
  id: string;
  name: string;
  rating: number;
  total_jobs: number;
};

type AnalyticsData = {
  overview: Overview;
  bookings_by_status: Record<string, number>;
  revenue_by_period: Array<{ period: string; amount: number }>;
  top_technicians: TopTechnician[];
  low_rated_technicians: LowRatedTechnician[];
};

const PERIOD_DAYS: Record<string, number> = { day: 1, week: 7, month: 30, year: 365 };

export default function AnalyticsDashboard() {
  const router = useRouter();
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [period, setPeriod] = useState("month");
  const [suspendingId, setSuspendingId] = useState<string | null>(null);

  useEffect(() => {
    const token = getStoredToken();
    if (!token) {
      router.replace("/");
      return;
    }
    void fetchAnalytics();
  }, [period]);

  async function fetchAnalytics() {
    try {
      setLoading(true);
      setError(null);
      const days = PERIOD_DAYS[period] ?? 30;
      const res = await api.get<AnalyticsData>(`/api/admin/analytics/overview?days=${days}`);
      setAnalytics(res.data);
    } catch {
      setError("Failed to load analytics. Make sure you are signed in as admin.");
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-slate-500">Loading analytics…</p>
      </div>
    );
  }

  if (error || !analytics) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-red-600">{error ?? "Failed to load analytics"}</p>
      </div>
    );
  }

  const totalBookings = analytics.overview.total_bookings || 1;

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-7xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-900">Analytics & Reports</h1>
            <p className="mt-1 text-slate-500">Platform performance and insights</p>
          </div>
          <div className="flex gap-2">
            {(["day", "week", "month", "year"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`rounded-lg px-4 py-2 text-sm font-medium transition ${
                  period === p
                    ? "bg-slate-900 text-white"
                    : "border border-slate-300 bg-white text-slate-700 hover:bg-slate-100"
                }`}
              >
                {p.charAt(0).toUpperCase() + p.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* Overview cards */}
        <div className="mb-8 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[
            { label: "Total Customers", value: analytics.overview.total_users },
            { label: "Technicians", value: analytics.overview.total_technicians },
            { label: "Total Bookings", value: analytics.overview.total_bookings },
            { label: "Total Revenue", value: `$${analytics.overview.total_revenue.toFixed(0)}` },
          ].map((card) => (
            <div key={card.label} className="rounded-xl border border-slate-200 bg-white p-5">
              <p className="text-xs font-semibold uppercase text-slate-500">{card.label}</p>
              <p className="mt-2 text-3xl font-bold text-slate-900">{card.value}</p>
            </div>
          ))}
        </div>

        <div className="mb-8 grid gap-6 lg:grid-cols-3">
          {/* Bookings by status */}
          <div className="lg:col-span-2 rounded-xl border border-slate-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-bold text-slate-900">Bookings by Status</h2>
            <div className="space-y-4">
              {Object.entries(analytics.bookings_by_status).map(([status, count]) => (
                <div key={status}>
                  <div className="mb-1 flex justify-between text-sm">
                    <span className="font-medium capitalize text-slate-700">{status.replace("_", " ")}</span>
                    <span className="font-bold text-slate-900">{count}</span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-slate-100">
                    <div
                      className={`h-2 rounded-full ${
                        status === "completed" ? "bg-emerald-500" :
                        status === "in_progress" ? "bg-blue-500" :
                        status === "pending" ? "bg-amber-500" : "bg-red-500"
                      }`}
                      style={{ width: `${Math.round((count / totalBookings) * 100)}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Revenue trend */}
          <div className="rounded-xl border border-slate-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-bold text-slate-900">Revenue</h2>
            <div className="space-y-3">
              {analytics.revenue_by_period.map((d) => (
                <div key={d.period}>
                  <p className="text-sm text-slate-500">{d.period}</p>
                  <p className="text-xl font-bold text-slate-900">${d.amount.toFixed(0)}</p>
                </div>
              ))}
              <div className="pt-2 border-t border-slate-100">
                <p className="text-xs text-slate-500">Total All Time</p>
                <p className="text-xl font-bold text-emerald-600">${analytics.overview.total_revenue.toFixed(0)}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          {/* Top technicians */}
          <div className="rounded-xl border border-slate-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-bold text-slate-900">Top Technicians</h2>
            {analytics.top_technicians.length === 0 ? (
              <p className="text-sm text-slate-500">No data yet</p>
            ) : (
              <div className="space-y-4">
                {analytics.top_technicians.map((tech, idx) => (
                  <div key={tech.id} className="flex items-center justify-between border-b border-slate-100 pb-3 last:border-0">
                    <div>
                      <p className="font-medium text-slate-900">#{idx + 1} {tech.name}</p>
                      <p className="text-sm text-slate-500">
                        ⭐ {tech.rating.toFixed(1)} · {tech.jobs_completed} jobs
                      </p>
                    </div>
                    <p className="font-bold text-emerald-600">
                      {tech.earnings > 0 ? `$${tech.earnings.toFixed(0)}` : "—"}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Low-rated technicians */}
          <div className="rounded-xl border border-slate-200 bg-white p-6">
            <h2 className="mb-1 text-lg font-bold text-slate-900">Low-Rated Technicians</h2>
            <p className="mb-4 text-sm text-slate-500">Below 3.0 rating — flag or suspend directly</p>
            {analytics.low_rated_technicians.length === 0 ? (
              <p className="py-6 text-center text-sm text-slate-500">No low-rated technicians 🎉</p>
            ) : (
              <div className="space-y-3">
                {analytics.low_rated_technicians.map((tech) => (
                  <div key={tech.id} className="rounded-lg border border-red-200 bg-red-50 p-3">
                    <div className="flex items-center justify-between gap-2">
                      <div>
                        <p className="font-medium text-slate-900">{tech.name}</p>
                        <p className="text-sm text-red-600">⭐ {tech.rating.toFixed(1)} ({tech.total_jobs} jobs)</p>
                      </div>
                      <div className="flex shrink-0 gap-2">
                        <a
                          href="/technicians"
                          className="rounded-md border border-slate-300 bg-white px-3 py-1 text-xs font-medium text-slate-700 hover:bg-slate-100"
                        >
                          Details
                        </a>
                        <button
                          onClick={async () => {
                            setSuspendingId(tech.id);
                            try {
                              await adminApi.suspendTechnician(tech.id);
                              setAnalytics((prev) =>
                                prev
                                  ? {
                                      ...prev,
                                      low_rated_technicians: prev.low_rated_technicians.filter(
                                        (t) => t.id !== tech.id
                                      ),
                                    }
                                  : prev
                              );
                            } catch {
                              alert("Failed to suspend technician.");
                            } finally {
                              setSuspendingId(null);
                            }
                          }}
                          disabled={suspendingId === tech.id}
                          className="rounded-md bg-red-600 px-3 py-1 text-xs font-medium text-white hover:bg-red-700 disabled:opacity-50"
                        >
                          {suspendingId === tech.id ? "…" : "Suspend"}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
