"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";

type PayoutRequest = {
  id: string;
  technician_id: string;
  technician_name: string;
  amount: number;
  status: "pending" | "approved" | "rejected" | "completed";
  request_date: string;
  approved_date?: string;
  reason?: string;
  account_details?: {
    payment_method: string; // "aba_pay" or "wing"
    account_number: string;
  };
  processing_fee?: number;
};

export default function PayoutManagement() {
  const [payouts, setPayouts] = useState<PayoutRequest[]>([]);
  const [filteredPayouts, setFilteredPayouts] = useState<PayoutRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>("pending");
  const [selectedPayout, setSelectedPayout] = useState<PayoutRequest | null>(
    null
  );
  const [rejectionReason, setRejectionReason] = useState("");

  useEffect(() => {
    fetchPayouts();
  }, []);

  const fetchPayouts = async () => {
    try {
      setLoading(true);
      // TODO: Replace with actual API endpoint
      // const response = await api.get("/api/admin/payouts");
      // setPayouts(response.data);
      setPayouts([]);
    } catch (error) {
      console.error("Error fetching payouts:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let filtered = payouts;

    if (filterStatus !== "all") {
      filtered = filtered.filter((payout) => payout.status === filterStatus);
    }

    setFilteredPayouts(filtered);
  }, [payouts, filterStatus]);

  const handleApprovePayout = async (payoutId: string) => {
    try {
      // TODO: Call approve API endpoint
      // await api.post(`/api/admin/payouts/${payoutId}/approve`);
      fetchPayouts();
      setSelectedPayout(null);
    } catch (error) {
      console.error("Error approving payout:", error);
    }
  };

  const handleRejectPayout = async (payoutId: string) => {
    if (!rejectionReason.trim()) {
      alert("Please provide a rejection reason");
      return;
    }

    try {
      // TODO: Call reject API endpoint
      // await api.post(`/api/admin/payouts/${payoutId}/reject`, {
      //   reason: rejectionReason,
      // });
      fetchPayouts();
      setSelectedPayout(null);
      setRejectionReason("");
    } catch (error) {
      console.error("Error rejecting payout:", error);
    }
  };

  const getTotalAmount = (payouts: PayoutRequest[]) => {
    return payouts.reduce((sum, p) => sum + p.amount, 0);
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Payout Management</h1>
          <p className="text-gray-600 mt-2">
            Review and process technician payout requests
          </p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          {["pending", "approved", "rejected", "completed"].map((status) => {
            const statusPayouts = payouts.filter((p) => p.status === status);
            return (
              <div
                key={status}
                className="bg-white rounded-lg border border-gray-200 p-6"
              >
                <p className="text-sm font-medium text-gray-600 uppercase">
                  {status}
                </p>
                <p className="text-2xl font-bold text-gray-900 mt-2">
                  {statusPayouts.length}
                </p>
                <p className="text-sm text-gray-600 mt-1">
                  ${getTotalAmount(statusPayouts).toFixed(2)}
                </p>
              </div>
            );
          })}
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 mb-6 overflow-x-auto">
          {["pending", "approved", "rejected", "completed", "all"].map((status) => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-6 py-2 rounded-lg font-medium transition whitespace-nowrap ${
                filterStatus === status
                  ? "bg-blue-600 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }`}
            >
              {status.charAt(0).toUpperCase() + status.slice(1)}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Payouts List */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
              {loading ? (
                <div className="p-8 text-center text-gray-500">Loading...</div>
              ) : filteredPayouts.length === 0 ? (
                <div className="p-8 text-center text-gray-500">
                  No payout requests found
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase">
                          Technician
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase">
                          Amount
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase">
                          Method
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase">
                          Status
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase">
                          Date
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase">
                          Action
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {filteredPayouts.map((payout) => (
                        <tr
                          key={payout.id}
                          onClick={() => setSelectedPayout(payout)}
                          className="hover:bg-gray-50 cursor-pointer"
                        >
                          <td className="px-6 py-4 font-medium text-gray-900">
                            {payout.technician_name}
                          </td>
                          <td className="px-6 py-4 font-bold text-gray-900">
                            ${payout.amount.toFixed(2)}
                          </td>
                          <td className="px-6 py-4 text-sm text-gray-600">
                            {payout.account_details?.payment_method === "aba_pay"
                              ? "ABA Pay"
                              : "Wing"}
                          </td>
                          <td className="px-6 py-4">
                            <span
                              className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${
                                payout.status === "completed"
                                  ? "bg-green-100 text-green-800"
                                  : payout.status === "approved"
                                  ? "bg-blue-100 text-blue-800"
                                  : payout.status === "rejected"
                                  ? "bg-red-100 text-red-800"
                                  : "bg-yellow-100 text-yellow-800"
                              }`}
                            >
                              {payout.status.charAt(0).toUpperCase() +
                                payout.status.slice(1)}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-sm text-gray-600">
                            {new Date(payout.request_date).toLocaleDateString()}
                          </td>
                          <td className="px-6 py-4">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedPayout(payout);
                              }}
                              className="text-blue-600 hover:text-blue-900 text-sm font-medium"
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
          </div>

          {/* Details Panel */}
          {selectedPayout && (
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <h2 className="font-bold text-lg text-gray-900 mb-4">
                {selectedPayout.technician_name}
              </h2>

              <div className="space-y-4 mb-6">
                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Amount
                  </p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">
                    ${selectedPayout.amount.toFixed(2)}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Processing Fee
                  </p>
                  <p className="text-sm text-gray-900 mt-1">
                    ${(selectedPayout.processing_fee || 0).toFixed(2)} (
                    {selectedPayout.processing_fee
                      ? ((selectedPayout.processing_fee / selectedPayout.amount) *
                          100).toFixed(1)
                      : "0"}
                    %)
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Payment Method
                  </p>
                  <p className="text-sm text-gray-900 mt-1">
                    {selectedPayout.account_details?.payment_method === "aba_pay"
                      ? "ABA Pay"
                      : "Wing"}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Account
                  </p>
                  <p className="text-sm text-gray-900 mt-1 font-mono">
                    {selectedPayout.account_details?.account_number}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Requested
                  </p>
                  <p className="text-sm text-gray-900 mt-1">
                    {new Date(selectedPayout.request_date).toLocaleDateString()}
                  </p>
                </div>

                {selectedPayout.reason && (
                  <div>
                    <p className="text-xs text-gray-600 uppercase font-semibold">
                      Note
                    </p>
                    <p className="text-sm text-gray-900 mt-1">
                      {selectedPayout.reason}
                    </p>
                  </div>
                )}
              </div>

              {selectedPayout.status === "pending" && (
                <div className="space-y-3">
                  <button
                    onClick={() => handleApprovePayout(selectedPayout.id)}
                    className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition"
                  >
                    Approve Payout
                  </button>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Rejection Reason (if rejecting)
                    </label>
                    <textarea
                      value={rejectionReason}
                      onChange={(e) => setRejectionReason(e.target.value)}
                      placeholder="Enter reason for rejection..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-red-500"
                      rows={3}
                    />
                  </div>

                  <button
                    onClick={() => handleRejectPayout(selectedPayout.id)}
                    className="w-full bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded-lg transition"
                  >
                    Reject Payout
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
