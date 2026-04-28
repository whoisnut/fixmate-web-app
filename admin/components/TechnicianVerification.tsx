import { useState, useEffect } from 'react';
import axios from 'axios';

interface Technician {
  id: string;
  user_id: string;
  name: string;
  email: string;
  phone: string;
  bio: string;
  specialties: string[];
  rating: number;
  total_jobs: number;
  is_verified: boolean;
  verification_status: string;
  rejection_reason?: string;
  documents: Array<{
    name: string;
    url: string;
    type: string;
    uploaded_at: string;
  }>;
  submitted_at: string;
  verified_at?: string;
}

interface VerificationStats {
  pending: number;
  verified: number;
  rejected: number;
  total: number;
}

export default function TechnicianVerification() {
  const [technicians, setTechnicians] = useState<Technician[]>([]);
  const [stats, setStats] = useState<VerificationStats>({
    pending: 0,
    verified: 0,
    rejected: 0,
    total: 0,
  });
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'verified' | 'rejected'>('pending');
  const [selectedTech, setSelectedTech] = useState<Technician | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  useEffect(() => {
    fetchTechnicians();
  }, []);

  const fetchTechnicians = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/admin/technicians');
      const data = response.data;

      setTechnicians(data);

      // Calculate stats
      const pending = data.filter((t: Technician) => t.verification_status === 'pending').length;
      const verified = data.filter((t: Technician) => t.is_verified).length;
      const rejected = data.filter((t: Technician) => t.verification_status === 'rejected').length;

      setStats({
        pending,
        verified,
        rejected,
        total: data.length,
      });
    } catch (error) {
      console.error('Error fetching technicians:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (technicianId: string) => {
    try {
      await axios.post(`/api/admin/technicians/${technicianId}/verify`);
      alert('Technician verified successfully');
      fetchTechnicians();
      setSelectedTech(null);
    } catch (error) {
      console.error('Error verifying technician:', error);
      alert('Error verifying technician');
    }
  };

  const handleReject = async (technicianId: string) => {
    if (!rejectionReason.trim()) {
      alert('Please provide a rejection reason');
      return;
    }

    try {
      await axios.post(`/api/admin/technicians/${technicianId}/reject`, {
        rejection_reason: rejectionReason,
      });
      alert('Technician rejected');
      fetchTechnicians();
      setSelectedTech(null);
      setRejectionReason('');
    } catch (error) {
      console.error('Error rejecting technician:', error);
      alert('Error rejecting technician');
    }
  };

  const filteredTechnicians = technicians.filter((tech) => {
    if (filter === 'all') return true;
    if (filter === 'pending') return tech.verification_status === 'pending';
    if (filter === 'verified') return tech.is_verified;
    if (filter === 'rejected') return tech.verification_status === 'rejected';
    return true;
  });

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="text-lg">Loading...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Technician Verification</h1>
        <p className="text-gray-600 mt-2">Manage and verify technician applications</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <StatCard
          label="Total"
          value={stats.total}
          bgColor="bg-blue-50"
          borderColor="border-blue-200"
          textColor="text-blue-600"
        />
        <StatCard
          label="Pending"
          value={stats.pending}
          bgColor="bg-yellow-50"
          borderColor="border-yellow-200"
          textColor="text-yellow-600"
        />
        <StatCard
          label="Verified"
          value={stats.verified}
          bgColor="bg-green-50"
          borderColor="border-green-200"
          textColor="text-green-600"
        />
        <StatCard
          label="Rejected"
          value={stats.rejected}
          bgColor="bg-red-50"
          borderColor="border-red-200"
          textColor="text-red-600"
        />
      </div>

      {/* Filters */}
      <div className="flex gap-2">
        {(['all', 'pending', 'verified', 'rejected'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg font-medium capitalize transition ${
              filter === f
                ? 'bg-blue-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            {f}
          </button>
        ))}
      </div>

      {/* Technicians List */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {filteredTechnicians.map((tech) => (
          <TechnicianCard
            key={tech.id}
            technician={tech}
            onSelect={() => setSelectedTech(tech)}
            isSelected={selectedTech?.id === tech.id}
          />
        ))}
      </div>

      {/* Detail Panel */}
      {selectedTech && (
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex justify-between items-start mb-6">
            <h2 className="text-2xl font-bold">{selectedTech.name}</h2>
            <button
              onClick={() => setSelectedTech(null)}
              className="text-gray-500 hover:text-gray-700 text-2xl"
            >
              ×
            </button>
          </div>

          <div className="grid grid-cols-2 gap-6 mb-8">
            {/* Basic Info */}
            <div>
              <h3 className="font-bold mb-4 text-lg">Contact Information</h3>
              <div className="space-y-3">
                <div>
                  <p className="text-gray-600 text-sm">Email</p>
                  <p className="font-medium">{selectedTech.email}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Phone</p>
                  <p className="font-medium">{selectedTech.phone}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Status</p>
                  <p className="font-medium capitalize">
                    <span
                      className={`px-3 py-1 rounded-full text-sm font-bold ${getStatusBadge(
                        selectedTech.verification_status
                      )}`}
                    >
                      {selectedTech.verification_status}
                    </span>
                  </p>
                </div>
              </div>
            </div>

            {/* Professional Info */}
            <div>
              <h3 className="font-bold mb-4 text-lg">Professional Information</h3>
              <div className="space-y-3">
                <div>
                  <p className="text-gray-600 text-sm">Rating</p>
                  <p className="font-medium">⭐ {selectedTech.rating.toFixed(1)} / 5.0</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Total Jobs Completed</p>
                  <p className="font-medium">{selectedTech.total_jobs}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Specialties</p>
                  <div className="flex flex-wrap gap-2 mt-1">
                    {selectedTech.specialties.map((spec) => (
                      <span
                        key={spec}
                        className="bg-blue-100 text-blue-700 px-2 py-1 rounded text-sm"
                      >
                        {spec}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Bio */}
          <div className="mb-8">
            <h3 className="font-bold mb-2">Professional Bio</h3>
            <p className="text-gray-700 bg-gray-50 p-4 rounded-lg">{selectedTech.bio}</p>
          </div>

          {/* Documents */}
          <div className="mb-8">
            <h3 className="font-bold mb-4">Uploaded Documents</h3>
            <div className="space-y-2">
              {selectedTech.documents.length > 0 ? (
                selectedTech.documents.map((doc, idx) => (
                  <div
                    key={idx}
                    className="flex items-center justify-between bg-gray-50 p-3 rounded-lg border border-gray-200"
                  >
                    <div className="flex items-center gap-3">
                      <svg
                        className="w-5 h-5 text-blue-600"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path d="M8 16.5a2.5 2.5 0 11 5 0 2.5 2.5 0 11-5 0z" />
                        <path
                          fillRule="evenodd"
                          d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z"
                          clipRule="evenodd"
                        />
                      </svg>
                      <div>
                        <p className="font-medium">{doc.name}</p>
                        <p className="text-sm text-gray-600">{doc.type}</p>
                      </div>
                    </div>
                    <a
                      href={doc.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-800 font-medium"
                    >
                      View
                    </a>
                  </div>
                ))
              ) : (
                <p className="text-gray-600">No documents uploaded</p>
              )}
            </div>
          </div>

          {/* Rejection Reason (if rejected) */}
          {selectedTech.verification_status === 'rejected' && (
            <div className="mb-8 bg-red-50 border border-red-200 p-4 rounded-lg">
              <h3 className="font-bold text-red-600 mb-2">Rejection Reason</h3>
              <p className="text-red-700">{selectedTech.rejection_reason}</p>
            </div>
          )}

          {/* Action Buttons */}
          {selectedTech.verification_status === 'pending' && (
            <div className="space-y-4">
              <button
                onClick={() => handleVerify(selectedTech.id)}
                className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-lg transition"
              >
                ✓ Approve Technician
              </button>

              <div>
                <textarea
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  placeholder="Reason for rejection (required if rejecting)"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-red-600"
                  rows={3}
                />
                <button
                  onClick={() => handleReject(selectedTech.id)}
                  className="w-full mt-2 bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-lg transition"
                >
                  ✕ Reject Application
                </button>
              </div>
            </div>
          )}

          {selectedTech.is_verified && (
            <div className="bg-green-50 border border-green-200 p-4 rounded-lg text-center">
              <p className="text-green-700 font-bold">✓ Verified on {selectedTech.verified_at}</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  bgColor,
  borderColor,
  textColor,
}: {
  label: string;
  value: number;
  bgColor: string;
  borderColor: string;
  textColor: string;
}) {
  return (
    <div className={`${bgColor} border ${borderColor} rounded-lg p-6`}>
      <p className="text-gray-600 text-sm">{label}</p>
      <p className={`${textColor} text-3xl font-bold mt-2`}>{value}</p>
    </div>
  );
}

function TechnicianCard({
  technician,
  onSelect,
  isSelected,
}: {
  technician: Technician;
  onSelect: () => void;
  isSelected: boolean;
}) {
  return (
    <div
      onClick={onSelect}
      className={`p-6 rounded-lg border cursor-pointer transition ${
        isSelected
          ? 'border-blue-600 bg-blue-50 shadow-lg'
          : 'border-gray-200 bg-white hover:border-gray-400 hover:shadow'
      }`}
    >
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="font-bold text-lg">{technician.name}</h3>
          <p className="text-gray-600 text-sm">{technician.email}</p>
        </div>
        <span
          className={`px-3 py-1 rounded-full text-sm font-bold ${getStatusBadge(
            technician.verification_status
          )}`}
        >
          {technician.verification_status}
        </span>
      </div>

      <div className="space-y-2">
        <div className="flex justify-between">
          <span className="text-gray-600">Rating:</span>
          <span className="font-medium">⭐ {technician.rating.toFixed(1)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-600">Jobs:</span>
          <span className="font-medium">{technician.total_jobs}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-600">Specialties:</span>
          <span className="font-medium">{technician.specialties.join(', ')}</span>
        </div>
      </div>
    </div>
  );
}

function getStatusBadge(status: string): string {
  switch (status) {
    case 'pending':
      return 'bg-yellow-100 text-yellow-700';
    case 'verified':
      return 'bg-green-100 text-green-700';
    case 'rejected':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}
