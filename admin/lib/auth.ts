"use client";

export type AdminUser = {
  id: string;
  name: string;
  email: string;
  role: string;
};

export function getStoredToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("token");
}

export function getStoredUser(): AdminUser | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem("admin_user");
    return raw ? (JSON.parse(raw) as AdminUser) : null;
  } catch {
    return null;
  }
}

export function clearAuth(): void {
  localStorage.removeItem("token");
  localStorage.removeItem("admin_user");
}
