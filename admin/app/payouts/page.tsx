"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/lib/api";
import { getStoredToken } from "@/lib/auth";

type Payout = {
  id: string;
  user_id: string;
  technician_name: string;
  amount: number;
  status: "pending" | "approved" | "rejected" | "completed";
  request_date?: string;
  approved_date?: string;
  reason?: string;
  account_details?: {
    payment_method: string;
    account_number: string;
  };
};

const statusColors: Record<string, string> = {
  pending: "bg-amber-100 text-amber-800",
  approved: "bg-blue-100 text-blue-800",
  rejected: "bg-red-100 text-red-800",
  completed: "bg-emerald-100 text-emerald-800",
};

export default function PayoutManagement() {
  const router = useRouter();
  const [payouts, setPayouts] = useState<Payout[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState("pending");
  const [selectedPayout, setSelectedPayout] = useState<Payout | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    if (!getStoredToken()) { router.replace("/"); return; }
    void fetchPayouts();
  }, []);

  async function fetchPayouts() {
    try {
      setLoading(true);
      setError(null);
      const res = await api.get<{ payouts: Payout[] }>("/api/payouts");
      setPayouts(res.data.payouts ?? []);
    } catch {
      setError("Failed to load payouts. Make sure you are signed in as admin.");
    } finally {
      setLoading(false);
    }
  }

  const filtered = useMemo(
    () => (filterStatus === "all" ? payouts : payouts.filter((p) => p.status === filterStatus)),
    [payouts, filterStatus]
  );

  const totalFor = (status: string) =>
    payouts.filter((p) => p.status === status).reduce((sum, p) => sum + p.amount, 0);

  async function handleApprove(payoutId: string) {
    setActionLoading(true);
    try {
      await api.post(`/api/payouts/${payoutId}/approve`);
      setNotice("Payout approved.");
      await fetchPayouts();
      setSelectedPayout(null);
    } catch {
      setError("Failed to approve payout.");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleReject(payoutId: string) {
    if (!rejectionReason.trim()) {
      alert("Please provide a rejection reason.");
      return;
    }
    setActionLoading(true);
    try {
      await api.post(`/api/payouts/${payoutId}/reject`, { reason: rejectionReason });
      setNotice("Payout rejected.");
      setRejectionReason("");
      await fetchPayouts();
      setSelectedPayout(null);
    } catch {
      setError("Failed to reject payout.");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleComplete(payoutId: string) {
    setActionLoading(true);
    try {
      await api.post(`/api/payouts/${payoutId}/complete`);
      setNotice("Payout marked as completed.");
      await fetchPayouts();
      setSelectedPayout(null);
    } catch {
      setError("Failed to complete payout.");
    } finally {
      setActionLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900">Payout Management</h1>
            <p className="mt-1 text-slate-500">Review and process technician payout requests</p>
          </div>
          <button
            onClick={() => void fetchPayouts()}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium hover:bg-slate-100"
          >
            Refresh
          </button>
        </div>

        {error && (
          <p className="mb-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
        )}
        {notice && (
          <p className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</p>
        )}

        {/* Stats */}
        <div className="mb-6 grid gap-4 md:grid-cols-4">
          {(["pending", "approved", "completed", "rejected"] as const).map((s) => (
            <div key={s} className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="text-xs font-semibold uppercase text-slate-500">{s}</p>
              <p className="mt-2 text-2xl font-bold text-slate-900">
                {payouts.filter((p) => p.status === s).length}
              </p>
              <p className="text-sm text-slate-500">${totalFor(s).toFixed(2)}</p>
            </div>
          ))}
        </div>

        {/* Filter tabs */}
        <div className="mb-6 flex flex-wrap gap-2">
          {(["pending", "approved", "completed", "rejected", "all"] as const).map((s) => (
            <button
              key={s}
              onClick={() => setFilterStatus(s)}
              className={`rounded-lg px-4 py-2 text-sm font-medium transition ${
                filterStatus === s
                  ? "bg-slate-900 text-white"
                  : "border border-slate-300 bg-white text-slate-700 hover:bg-slate-100"
              }`}
            >
              {s.charAt(0).toUpperCase() + s.slice(1)}
            </button>
          ))}
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          {/* List */}
          <div className="lg:col-span-2 overflow-hidden rounded-xl border border-slate-200 bg-white">
            {loading ? (
              <div className="p-10 text-center text-slate-500">Loading…</div>
            ) : filtered.length === 0 ? (
              <div className="p-10 text-center text-slate-500">No payout requests</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-left text-xs font-semibold uppercase text-slate-600">
                    <tr>
                      <th className="px-4 py-3">Technician</th>
                      <th className="px-4 py-3">Amount</th>
                      <th className="px-4 py-3">Method</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Date</th>
                      <th className="px-4 py-3"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filtered.map((payout) => (
                      <tr
                        key={payout.id}
                        className={`cursor-pointer hover:bg-slate-50 ${
                          selectedPayout?.id === payout.id ? "bg-sky-50" : ""
                        }`}
                        onClick={() => setSelectedPayout(payout)}
                      >
                        <td className="px-4 py-3 font-medium text-slate-900">{payout.technician_name}</td>
                        <td className="px-4 py-3 font-bold text-slate-900">${payout.amount.toFixed(2)}</td>
                        <td className="px-4 py-3 text-slate-600">
                          {payout.account_details?.payment_method === "aba_pay" ? "ABA Pay" :
                           payout.account_details?.payment_method === "wing" ? "Wing" :
                           payout.account_details?.payment_method ?? "—"}
                        </td>
                        <td className="px-4 py-3">
                          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${statusColors[payout.status] ?? ""}`}>
                            {payout.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-slate-500">
                          {payout.request_date ? new Date(payout.request_date).toLocaleDateString() : "—"}
                        </td>
                        <td className="px-4 py-3">
                          <button
                            onClick={(e) => { e.stopPropagation(); setSelectedPayout(payout); }}
                            className="text-sm font-medium text-sky-600 hover:underline"
                          >
                            Details
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Detail */}
          {selectedPayout && (
            <div className="rounded-xl border border-slate-200 bg-white p-6">
              <h2 className="mb-4 text-lg font-bold text-slate-900">{selectedPayout.technician_name}</h2>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Amount</p>
                  <p className="mt-1 text-2xl font-bold text-slate-900">${selectedPayout.amount.toFixed(2)}</p>
                </div>
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Payment Method</p>
                  <p className="mt-1 text-slate-800">
                    {selectedPayout.account_details?.payment_method === "aba_pay" ? "ABA Pay" :
                     selectedPayout.account_details?.payment_method === "wing" ? "Wing" :
                     selectedPayout.account_details?.payment_method ?? "—"}
                  </p>
                </div>
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Account Number</p>
                  <p className="mt-1 font-mono text-slate-800">{selectedPayout.account_details?.account_number ?? "—"}</p>
                </div>
                <div>
                  <p className="text-xs font-semibold uppercase text-slate-500">Requested</p>
                  <p className="mt-1 text-slate-800">
                    {selectedPayout.request_date ? new Date(selectedPayout.request_date).toLocaleDateString() : "—"}
                  </p>
                </div>
                {selectedPayout.reason && (
                  <div>
                    <p className="text-xs font-semibold uppercase text-slate-500">Note</p>
                    <p className="mt-1 text-slate-800">{selectedPayout.reason}</p>
                  </div>
                )}
              </div>

              <div className="mt-6 space-y-2">
                {selectedPayout.status === "pending" && (
                  <>
                    <button
                      disabled={actionLoading}
                      onClick={() => void handleApprove(selectedPayout.id)}
                      className="w-full rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-500 disabled:opacity-60"
                    >
                      Approve Payout
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
                      onClick={() => void handleReject(selectedPayout.id)}
                      className="w-full rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500 disabled:opacity-60"
                    >
                      Reject Payout
                    </button>
                  </>
                )}
                {selectedPayout.status === "approved" && (
                  <button
                    disabled={actionLoading}
                    onClick={() => void handleComplete(selectedPayout.id)}
                    className="w-full rounded-lg bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500 disabled:opacity-60"
                  >
                    Mark as Completed
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
