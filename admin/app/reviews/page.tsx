"use client";

import { useEffect, useState } from "react";
import { adminApi } from "@/lib/api";

type Review = {
  id: string;
  booking_id: string;
  rating: number;
  comment: string | null;
  created_at: string;
  customer_id: string | null;
  customer_name: string;
  technician_id: string | null;
  technician_name: string;
};

type ReviewsData = {
  total: number;
  reviews: Review[];
};

const STAR_FILTERS = [
  { label: "All", min: 1, max: 5 },
  { label: "⭐ 1–2", min: 1, max: 2 },
  { label: "⭐⭐⭐ 3", min: 3, max: 3 },
  { label: "⭐⭐⭐⭐ 4–5", min: 4, max: 5 },
];

function StarRating({ rating }: { rating: number }) {
  return (
    <span className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((s) => (
        <svg
          key={s}
          className={`h-4 w-4 ${s <= rating ? "text-amber-400" : "text-slate-200"}`}
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
        </svg>
      ))}
    </span>
  );
}

export default function ReviewsPage() {
  const [data, setData] = useState<ReviewsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterIdx, setFilterIdx] = useState(0);
  const [search, setSearch] = useState("");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [confirmId, setConfirmId] = useState<string | null>(null);
  const [suspendingId, setSuspendingId] = useState<string | null>(null);

  useEffect(() => {
    void fetchReviews();
  }, []);

  async function fetchReviews() {
    try {
      setLoading(true);
      setError(null);
      const res = await adminApi.getReviews();
      setData(res.data as ReviewsData);
    } catch {
      setError("Failed to load reviews. Make sure you are signed in as admin.");
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete(reviewId: string) {
    setDeletingId(reviewId);
    try {
      await adminApi.deleteReview(reviewId);
      setData((prev) =>
        prev
          ? {
              ...prev,
              total: prev.total - 1,
              reviews: prev.reviews.filter((r) => r.id !== reviewId),
            }
          : prev
      );
    } catch {
      alert("Failed to delete review.");
    } finally {
      setDeletingId(null);
      setConfirmId(null);
    }
  }

  async function handleSuspendTechnician(technicianId: string) {
    if (!technicianId) return;
    setSuspendingId(technicianId);
    try {
      await adminApi.suspendTechnician(technicianId);
      alert("Technician suspended successfully.");
    } catch {
      alert("Failed to suspend technician.");
    } finally {
      setSuspendingId(null);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-slate-500">Loading reviews…</p>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-red-600">{error ?? "Failed to load reviews"}</p>
      </div>
    );
  }

  const { min, max } = STAR_FILTERS[filterIdx];
  const filtered = data.reviews.filter((r) => {
    const inRange = r.rating >= min && r.rating <= max;
    if (!search.trim()) return inRange;
    const q = search.toLowerCase();
    return (
      inRange &&
      (r.customer_name.toLowerCase().includes(q) ||
        r.technician_name.toLowerCase().includes(q) ||
        (r.comment ?? "").toLowerCase().includes(q))
    );
  });

  const avgRating =
    data.reviews.length > 0
      ? data.reviews.reduce((s, r) => s + r.rating, 0) / data.reviews.length
      : 0;
  const lowRatedCount = data.reviews.filter((r) => r.rating <= 2).length;

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-7xl">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-slate-900">Review Moderation</h1>
          <p className="mt-1 text-slate-500">
            Monitor customer feedback and manage problematic reviews
          </p>
        </div>

        {/* Stats */}
        <div className="mb-8 grid gap-4 sm:grid-cols-3">
          {[
            { label: "Total Reviews", value: data.total, color: "text-slate-900" },
            {
              label: "Average Rating",
              value: `${avgRating.toFixed(1)} ⭐`,
              color: "text-amber-600",
            },
            {
              label: "Low-Rated (1–2★)",
              value: lowRatedCount,
              color: lowRatedCount > 0 ? "text-red-600" : "text-emerald-600",
            },
          ].map((s) => (
            <div
              key={s.label}
              className="rounded-xl border border-slate-200 bg-white p-5"
            >
              <p className="text-xs font-semibold uppercase text-slate-500">
                {s.label}
              </p>
              <p className={`mt-2 text-3xl font-bold ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Filters + search */}
        <div className="mb-6 flex flex-wrap items-center gap-3">
          <div className="flex gap-2">
            {STAR_FILTERS.map((f, i) => (
              <button
                key={f.label}
                onClick={() => setFilterIdx(i)}
                className={`rounded-lg px-3 py-1.5 text-sm font-medium transition ${
                  filterIdx === i
                    ? "bg-slate-900 text-white"
                    : "border border-slate-300 bg-white text-slate-700 hover:bg-slate-100"
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
          <input
            type="text"
            placeholder="Search customer, technician, or comment…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="ml-auto rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-sky-500"
          />
        </div>

        {/* Table */}
        {filtered.length === 0 ? (
          <div className="rounded-xl border border-slate-200 bg-white py-16 text-center">
            <p className="text-slate-500">No reviews match the current filter.</p>
          </div>
        ) : (
          <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
            <table className="w-full text-sm">
              <thead className="border-b border-slate-200 bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left font-semibold text-slate-600">
                    Rating
                  </th>
                  <th className="px-4 py-3 text-left font-semibold text-slate-600">
                    Comment
                  </th>
                  <th className="px-4 py-3 text-left font-semibold text-slate-600">
                    Customer
                  </th>
                  <th className="px-4 py-3 text-left font-semibold text-slate-600">
                    Technician
                  </th>
                  <th className="px-4 py-3 text-left font-semibold text-slate-600">
                    Date
                  </th>
                  <th className="px-4 py-3 text-right font-semibold text-slate-600">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filtered.map((review) => (
                  <tr
                    key={review.id}
                    className={`transition hover:bg-slate-50 ${
                      review.rating <= 2 ? "bg-red-50/40" : ""
                    }`}
                  >
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        <StarRating rating={review.rating} />
                        {review.rating <= 2 && (
                          <span className="inline-block rounded-full bg-red-100 px-2 py-0.5 text-xs font-semibold text-red-700">
                            Low Rating
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="max-w-xs px-4 py-3">
                      <p className="line-clamp-2 text-slate-700">
                        {review.comment ?? (
                          <span className="italic text-slate-400">No comment</span>
                        )}
                      </p>
                    </td>
                    <td className="px-4 py-3 font-medium text-slate-900">
                      {review.customer_name}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        <span className="font-medium text-slate-900">
                          {review.technician_name}
                        </span>
                        {review.rating <= 2 && review.technician_id && (
                          <button
                            onClick={() =>
                              handleSuspendTechnician(review.technician_id!)
                            }
                            disabled={suspendingId === review.technician_id}
                            className="w-fit rounded bg-orange-100 px-2 py-0.5 text-xs font-semibold text-orange-700 hover:bg-orange-200 disabled:opacity-50"
                          >
                            {suspendingId === review.technician_id
                              ? "Suspending…"
                              : "Flag & Suspend"}
                          </button>
                        )}
                      </div>
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-slate-500">
                      {new Date(review.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {confirmId === review.id ? (
                        <div className="flex items-center justify-end gap-2">
                          <span className="text-xs text-slate-600">Delete?</span>
                          <button
                            onClick={() => handleDelete(review.id)}
                            disabled={deletingId === review.id}
                            className="rounded bg-red-600 px-2 py-1 text-xs font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                          >
                            {deletingId === review.id ? "…" : "Yes"}
                          </button>
                          <button
                            onClick={() => setConfirmId(null)}
                            className="rounded border border-slate-300 px-2 py-1 text-xs font-semibold text-slate-600 hover:bg-slate-100"
                          >
                            No
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => setConfirmId(review.id)}
                          className="rounded border border-red-200 px-3 py-1 text-xs font-semibold text-red-600 hover:bg-red-50"
                        >
                          Delete
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <p className="mt-4 text-right text-xs text-slate-400">
          Showing {filtered.length} of {data.total} reviews
        </p>
      </div>
    </div>
  );
}
