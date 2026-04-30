"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";

type Technician = {
  id: string;
  user_id: string;
  name: string;
  email: string;
  phone?: string;
  specialties: string[];
  bio: string;
  documents: Array<{ name: string; url: string; type: string }>;
  verification_status: "pending" | "verified" | "rejected";
  submitted_at?: string;
  verified_at?: string;
  rejection_reason?: string;
  rating: number;
  total_jobs: number;
  is_active: boolean;
  is_verified: boolean;
};

const statusColors: Record<string, string> = {
  verified: "bg-green-100 text-green-800",
  pending: "bg-yellow-100 text-yellow-800",
  rejected: "bg-red-100 text-red-800",
};

export default function TechnicianVerification() {
  const [technicians, setTechnicians] = useState<Technician[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>("pending");
  const [selectedTech, setSelectedTech] = useState<Technician | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    void fetchTechnicians();
  }, []);

  async function fetchTechnicians() {
    try {
      setLoading(true);
      setError(null);
      const res = await api.get<{ technicians: Technician[] }>("/api/admin/technicians");
      setTechnicians(res.data.technicians ?? []);
    } catch {
      setError("Failed to load technicians. Make sure you are signed in as admin.");
    } finally {
      setLoading(false);
    }
  }

  const filtered =
    filterStatus === "all"
      ? technicians
      : technicians.filter((t) => t.verification_status === filterStatus);

  const countOf = (status: string) =>
    status === "all"
      ? technicians.length
      : technicians.filter((t) => t.verification_status === status).length;

  async function handleApprove(techId: string) {
    setActionLoading(true);
    try {
      await api.post(`/api/admin/technicians/${techId}/verify`);
      await fetchTechnicians();
      setSelectedTech(null);
    } catch {
      setError("Failed to approve technician.");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleReject(techId: string) {
    if (!rejectionReason.trim()) {
      alert("Please provide a rejection reason.");
      return;
    }
    setActionLoading(true);
    try {
      await api.post(`/api/admin/technicians/${techId}/reject`, { reason: rejectionReason });
      setRejectionReason("");
      await fetchTechnicians();
      setSelectedTech(null);
    } catch {
      setError("Failed to reject technician.");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleSuspend(techId: string) {
    setActionLoading(true);
    try {
      await api.post(`/api/admin/technicians/${techId}/suspend`);
      await fetchTechnicians();
      setSelectedTech(null);
    } catch {
      setError("Failed to suspend technician.");
    } finally {
      setActionLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900">Technician Verification</h1>
            <p className="mt-1 text-slate-500">Review and approve technician registrations</p>
          </div>
          <button
            onClick={() => void fetchTechnicians()}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium hover:bg-slate-100"
          >
            Refresh
          </button>
        </div>

        {error && (
          <p className="mb-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
            {error}
          </p>
        )}

        {/* Filter tabs */}
        <div className="mb-6 flex flex-wrap gap-2">
          {(["pending", "verified", "rejected", "all"] as const).map((s) => (
            <button
              key={s}
              onClick={() => setFilterStatus(s)}
              className={`rounded-lg px-4 py-2 text-sm font-medium transition ${
                filterStatus === s
                  ? "bg-slate-900 text-white"
                  : "border border-slate-300 bg-white text-slate-700 hover:bg-slate-100"
              }`}
            >
              {s.charAt(0).toUpperCase() + s.slice(1)} ({countOf(s)})
            </button>
          ))}
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          {/* List */}
          <div className="lg:col-span-2 rounded-xl border border-slate-200 bg-white overflow-hidden">
            {loading ? (
              <div className="p-10 text-center text-slate-500">Loading...</div>
            ) : filtered.length === 0 ? (
              <div className="p-10 text-center text-slate-500">No technicians found</div>
            ) : (
              <div className="divide-y divide-slate-100">
                {filtered.map((tech) => (
                  <div
                    key={tech.id}
                    onClick={() => setSelectedTech(tech)}
                    className={`cursor-pointer p-5 transition hover:bg-slate-50 ${
                      selectedTech?.id === tech.id ? "border-l-4 border-sky-600 bg-sky-50" : ""
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-semibold text-slate-900">{tech.name}</p>
                        <p className="text-sm text-slate-500">{tech.email}</p>
                        {tech.phone && <p className="text-sm text-slate-500">{tech.phone}</p>}
                        <div className="mt-2 flex flex-wrap gap-1">
                          {(tech.specialties ?? []).map((s) => (
                            <span key={s} className="rounded bg-purple-100 px-2 py-0.5 text-xs text-purple-800">
                              {s}
                            </span>
                          ))}
                        </div>
                      </div>
                      <div className="text-right shrink-0 ml-4">
                        <span className={`rounded-full px-3 py-1 text-xs font-semibold ${statusColors[tech.verification_status] ?? ""}`}>
                          {tech.verification_status}
                        </span>
                        {tech.rating > 0 && (
                          <p className="mt-1 text-sm text-slate-600">
                            ⭐ {tech.rating.toFixed(1)} ({tech.total_jobs} jobs)
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Detail panel */}
          {selectedTech && (
            <div className="rounded-xl border border-slate-200 bg-white p-6">
              <h2 className="mb-4 text-lg font-bold text-slate-900">{selectedTech.name}</h2>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Bio</p>
                  <p className="mt-1 text-slate-800">{selectedTech.bio || "—"}</p>
                </div>
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Specialties</p>
                  <div className="mt-1 flex flex-wrap gap-1">
                    {(selectedTech.specialties ?? []).map((s) => (
                      <span key={s} className="rounded bg-purple-100 px-2 py-0.5 text-xs text-purple-800">{s}</span>
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Documents</p>
                  <div className="mt-1 space-y-1">
                    {(selectedTech.documents ?? []).length === 0 ? (
                      <p className="text-slate-500">No documents</p>
                    ) : (
                      selectedTech.documents.map((doc, i) => (
                        <a key={i} href={doc.url} target="_blank" rel="noopener noreferrer"
                          className="block text-sky-600 hover:underline break-all">
                          {doc.name} ({doc.type})
                        </a>
                      ))
                    )}
                  </div>
                </div>
                {selectedTech.submitted_at && (
                  <div>
                    <p className="text-xs font-semibold uppercase text-slate-500">Submitted</p>
                    <p className="mt-1 text-slate-800">{new Date(selectedTech.submitted_at).toLocaleDateString()}</p>
                  </div>
                )}
                {selectedTech.rejection_reason && (
                  <div>
                    <p className="text-xs font-semibold uppercase text-slate-500">Rejection Reason</p>
                    <p className="mt-1 text-red-700">{selectedTech.rejection_reason}</p>
                  </div>
                )}
              </div>

              <div className="mt-6 space-y-2">
                {selectedTech.verification_status === "pending" && (
                  <>
                    <button
                      disabled={actionLoading}
                      onClick={() => void handleApprove(selectedTech.id)}
                      className="w-full rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-500 disabled:opacity-60"
                    >
                      Approve
                    </button>
                    <textarea
                      value={rejectionReason}
                      onChange={(e) => setRejectionReason(e.target.value)}
                      placeholder="Rejection reason…"
                      rows={2}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    />
                    <button
                      disabled={actionLoading}
                      onClick={() => void handleReject(selectedTech.id)}
                      className="w-full rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500 disabled:opacity-60"
                    >
                      Reject
                    </button>
                  </>
                )}
                {selectedTech.is_active && (
                  <button
                    disabled={actionLoading}
                    onClick={() => void handleSuspend(selectedTech.id)}
                    className="w-full rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100 disabled:opacity-60"
                  >
                    Suspend Account
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
