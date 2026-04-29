"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";

type TechnicianRequest = {
  id: string;
  user_id: string;
  name: string;
  email: string;
  phone: string;
  specialties: string[];
  bio: string;
  documents: Array<{
    name: string;
    url: string;
    type: string;
  }>;
  verification_status: "pending" | "approved" | "rejected";
  submitted_at: string;
  verified_at?: string;
  rejection_reason?: string;
  rating: number;
  total_jobs: number;
};

export default function TechnicianVerification() {
  const [technicians, setTechnicians] = useState<TechnicianRequest[]>([]);
  const [filteredTechnicians, setFilteredTechnicians] = useState<
    TechnicianRequest[]
  >([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>("pending");
  const [selectedTech, setSelectedTech] = useState<TechnicianRequest | null>(
    null
  );
  const [rejectionReason, setRejectionReason] = useState("");

  useEffect(() => {
    fetchTechnicians();
  }, []);

  const fetchTechnicians = async () => {
    try {
      setLoading(true);
      // TODO: Replace with actual API endpoint
      // const response = await api.get("/api/admin/technicians");
      // setTechnicians(response.data);
      setTechnicians([]);
    } catch (error) {
      console.error("Error fetching technicians:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let filtered = technicians;

    if (filterStatus !== "all") {
      filtered = filtered.filter((tech) => tech.verification_status === filterStatus);
    }

    setFilteredTechnicians(filtered);
  }, [technicians, filterStatus]);

  const handleApproveTechnician = async (techId: string) => {
    try {
      // TODO: Call approve API endpoint
      // await api.post(`/api/admin/technicians/${techId}/verify`);
      fetchTechnicians();
      setSelectedTech(null);
    } catch (error) {
      console.error("Error approving technician:", error);
    }
  };

  const handleRejectTechnician = async (techId: string) => {
    if (!rejectionReason.trim()) {
      alert("Please provide a rejection reason");
      return;
    }

    try {
      // TODO: Call reject API endpoint
      // await api.post(`/api/admin/technicians/${techId}/reject`, {
      //   reason: rejectionReason,
      // });
      fetchTechnicians();
      setSelectedTech(null);
      setRejectionReason("");
    } catch (error) {
      console.error("Error rejecting technician:", error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">
            Technician Verification
          </h1>
          <p className="text-gray-600 mt-2">
            Review and approve technician registration requests
          </p>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-4 mb-6">
          {["pending", "approved", "rejected", "all"].map((status) => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-6 py-2 rounded-lg font-medium transition ${
                filterStatus === status
                  ? "bg-blue-600 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }`}
            >
              {status.charAt(0).toUpperCase() + status.slice(1)} (
              {technicians.filter(
                (t) => t.verification_status === status || status === "all"
              ).length}
              )
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Technicians List */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
              {loading ? (
                <div className="p-8 text-center text-gray-500">Loading...</div>
              ) : filteredTechnicians.length === 0 ? (
                <div className="p-8 text-center text-gray-500">
                  No technicians found
                </div>
              ) : (
                <div className="divide-y divide-gray-200">
                  {filteredTechnicians.map((tech) => (
                    <div
                      key={tech.id}
                      onClick={() => setSelectedTech(tech)}
                      className={`p-6 cursor-pointer transition ${
                        selectedTech?.id === tech.id
                          ? "bg-blue-50 border-l-4 border-blue-600"
                          : "hover:bg-gray-50"
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <h3 className="font-bold text-gray-900">
                            {tech.name}
                          </h3>
                          <p className="text-sm text-gray-600">{tech.email}</p>
                          <p className="text-sm text-gray-600">{tech.phone}</p>
                          <div className="mt-2 flex gap-2">
                            {tech.specialties.map((spec) => (
                              <span
                                key={spec}
                                className="inline-block px-2 py-1 text-xs bg-purple-100 text-purple-800 rounded"
                              >
                                {spec}
                              </span>
                            ))}
                          </div>
                        </div>
                        <div className="text-right">
                          <span
                            className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${
                              tech.verification_status === "approved"
                                ? "bg-green-100 text-green-800"
                                : tech.verification_status === "rejected"
                                ? "bg-red-100 text-red-800"
                                : "bg-yellow-100 text-yellow-800"
                            }`}
                          >
                            {tech.verification_status.charAt(0).toUpperCase() +
                              tech.verification_status.slice(1)}
                          </span>
                          {tech.rating > 0 && (
                            <div className="text-sm font-medium mt-2">
                              ⭐ {tech.rating.toFixed(1)}{" "}
                              <span className="text-gray-600">
                                ({tech.total_jobs} jobs)
                              </span>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Details Panel */}
          {selectedTech && (
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <h2 className="font-bold text-lg text-gray-900 mb-4">
                {selectedTech.name}
              </h2>

              <div className="space-y-4 mb-6">
                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Bio
                  </p>
                  <p className="text-sm text-gray-900 mt-1">
                    {selectedTech.bio || "No bio provided"}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Specialties
                  </p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {selectedTech.specialties.map((spec) => (
                      <span
                        key={spec}
                        className="inline-block px-2 py-1 text-xs bg-purple-100 text-purple-800 rounded"
                      >
                        {spec}
                      </span>
                    ))}
                  </div>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Documents
                  </p>
                  <div className="mt-2 space-y-2">
                    {selectedTech.documents.map((doc, idx) => (
                      <a
                        key={idx}
                        href={doc.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="block text-sm text-blue-600 hover:text-blue-900 break-all"
                      >
                        {doc.name} ({doc.type})
                      </a>
                    ))}
                  </div>
                </div>

                <div>
                  <p className="text-xs text-gray-600 uppercase font-semibold">
                    Submitted
                  </p>
                  <p className="text-sm text-gray-900 mt-1">
                    {new Date(selectedTech.submitted_at).toLocaleDateString()}
                  </p>
                </div>
              </div>

              {selectedTech.verification_status === "pending" && (
                <div className="space-y-3">
                  <button
                    onClick={() => handleApproveTechnician(selectedTech.id)}
                    className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition"
                  >
                    Approve Technician
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
                    onClick={() =>
                      handleRejectTechnician(selectedTech.id)
                    }
                    className="w-full bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded-lg transition"
                  >
                    Reject Technician
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
