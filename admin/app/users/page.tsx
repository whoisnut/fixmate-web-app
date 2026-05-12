"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/lib/api";
import { getStoredToken } from "@/lib/auth";

type User = {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role: string;
  is_active: boolean;
  created_at: string;
};

export default function UserManagement() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterRole, setFilterRole] = useState("all");
  const [filterStatus, setFilterStatus] = useState("all");

  useEffect(() => {
    if (!getStoredToken()) { router.replace("/"); return; }
    void fetchUsers();
  }, []);

  async function fetchUsers() {
    try {
      setLoading(true);
      setError(null);
      const res = await api.get<{ users: User[] }>("/api/admin/users");
      setUsers(res.data.users ?? []);
    } catch {
      setError("Failed to load users. Make sure you are signed in as admin.");
    } finally {
      setLoading(false);
    }
  }

  const filtered = useMemo(() => {
    return users.filter((u) => {
      const matchesSearch =
        !searchTerm ||
        u.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.email.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesRole = filterRole === "all" || u.role === filterRole;
      const matchesStatus =
        filterStatus === "all" ||
        (filterStatus === "active" ? u.is_active : !u.is_active);
      return matchesSearch && matchesRole && matchesStatus;
    });
  }, [users, searchTerm, filterRole, filterStatus]);

  async function handleSuspend(userId: string) {
    try {
      await api.post(`/api/admin/users/${userId}/suspend`);
      setNotice("User suspended.");
      await fetchUsers();
    } catch {
      setError("Failed to suspend user.");
    }
  }

  async function handleUnsuspend(userId: string) {
    try {
      await api.post(`/api/admin/users/${userId}/unsuspend`);
      setNotice("User reactivated.");
      await fetchUsers();
    } catch {
      setError("Failed to reactivate user.");
    }
  }

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900">User Management</h1>
            <p className="mt-1 text-slate-500">Manage and moderate all accounts</p>
          </div>
          <button
            onClick={() => void fetchUsers()}
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

        {/* Filters */}
        <div className="mb-6 grid gap-3 rounded-xl border border-slate-200 bg-white p-4 md:grid-cols-4">
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase text-slate-500">Search</label>
            <input
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Name or email…"
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase text-slate-500">Role</label>
            <select
              value={filterRole}
              onChange={(e) => setFilterRole(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            >
              <option value="all">All Roles</option>
              <option value="customer">Customer</option>
              <option value="technician">Technician</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase text-slate-500">Status</label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            >
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase text-slate-500">Results</label>
            <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700">
              {filtered.length} users
            </div>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
          {loading ? (
            <div className="p-10 text-center text-slate-500">Loading…</div>
          ) : filtered.length === 0 ? (
            <div className="p-10 text-center text-slate-500">No users found</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs font-semibold uppercase text-slate-600">
                  <tr>
                    <th className="px-4 py-3">Name</th>
                    <th className="px-4 py-3">Email</th>
                    <th className="px-4 py-3">Role</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Joined</th>
                    <th className="px-4 py-3">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filtered.map((user) => (
                    <tr key={user.id} className="hover:bg-slate-50">
                      <td className="px-4 py-3 font-medium text-slate-900">{user.name}</td>
                      <td className="px-4 py-3 text-slate-600">{user.email}</td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                          user.role === "technician"
                            ? "bg-purple-100 text-purple-800"
                            : user.role === "admin"
                            ? "bg-red-100 text-red-800"
                            : "bg-blue-100 text-blue-800"
                        }`}>
                          {user.role}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                          user.is_active ? "bg-emerald-100 text-emerald-800" : "bg-red-100 text-red-800"
                        }`}>
                          {user.is_active ? "Active" : "Suspended"}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-slate-500">
                        {new Date(user.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3">
                        {user.is_active ? (
                          <button
                            onClick={() => void handleSuspend(user.id)}
                            className="text-sm font-medium text-red-600 hover:text-red-900"
                          >
                            Suspend
                          </button>
                        ) : (
                          <button
                            onClick={() => void handleUnsuspend(user.id)}
                            className="text-sm font-medium text-emerald-600 hover:text-emerald-900"
                          >
                            Activate
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
