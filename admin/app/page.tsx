'use client';

import { useEffect, useMemo, useState } from 'react';
import api from '@/lib/api';

type User = {
  id: string;
  name: string;
  email: string;
  role: string;
};

type LoginResponse = {
  access_token: string;
  user: User;
};

type Category = {
  id: string;
  name: string;
  icon?: string;
  color_hex: string;
  is_active: boolean;
};

type Service = {
  id: string;
  category_id: string;
  name: string;
  description?: string;
  min_price: number;
  max_price: number;
  urgency_level: number;
  is_active: boolean;
};

type Booking = {
  id: string;
  customer_id: string;
  technician_id?: string | null;
  service_id: string;
  address: string;
  scheduled_at: string;
  status: string;
};

type ViewTab = 'overview' | 'categories' | 'services' | 'bookings';

const statusClass: Record<string, string> = {
  pending: 'bg-amber-100 text-amber-800 border-amber-200',
  accepted: 'bg-blue-100 text-blue-800 border-blue-200',
  in_progress: 'bg-indigo-100 text-indigo-800 border-indigo-200',
  completed: 'bg-emerald-100 text-emerald-800 border-emerald-200',
  cancelled: 'bg-rose-100 text-rose-800 border-rose-200',
};

export default function Home() {
  const [activeTab, setActiveTab] = useState<ViewTab>('overview');
  const [email, setEmail] = useState('admin@fixmate.dev');
  const [password, setPassword] = useState('Admin1234');
  const [token, setToken] = useState<string | null>(null);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>('all');
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthLoading, setIsAuthLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const [categoryName, setCategoryName] = useState('');
  const [categoryIcon, setCategoryIcon] = useState('');
  const [categoryColor, setCategoryColor] = useState('#0EA5E9');

  const [serviceName, setServiceName] = useState('');
  const [serviceDescription, setServiceDescription] = useState('');
  const [serviceMinPrice, setServiceMinPrice] = useState('0');
  const [serviceMaxPrice, setServiceMaxPrice] = useState('0');
  const [serviceUrgency, setServiceUrgency] = useState('1');
  const [serviceCategoryId, setServiceCategoryId] = useState('');

  useEffect(() => {
    const storedToken = localStorage.getItem('token');
    const storedUser = localStorage.getItem('admin_user');
    if (storedToken) {
      setToken(storedToken);
    }
    if (storedUser) {
      setCurrentUser(JSON.parse(storedUser));
    }
  }, []);

  useEffect(() => {
    void loadPublicData();
  }, []);

  useEffect(() => {
    if (token) {
      void loadBookings();
    }
  }, [token]);

  const filteredServices = useMemo(() => {
    if (selectedCategoryId === 'all') return services;
    return services.filter(
      (service) => service.category_id === selectedCategoryId,
    );
  }, [services, selectedCategoryId]);

  const completedCount = bookings.filter(
    (booking) => booking.status === 'completed',
  ).length;
  const pendingCount = bookings.filter(
    (booking) => booking.status === 'pending',
  ).length;

  async function loadPublicData() {
    setIsLoading(true);
    setError(null);
    try {
      const [categoriesRes, servicesRes] = await Promise.all([
        api.get<Category[]>('/api/services/categories'),
        api.get<Service[]>('/api/services'),
      ]);
      setCategories(categoriesRes.data);
      setServices(servicesRes.data);
      if (!serviceCategoryId && categoriesRes.data.length > 0) {
        setServiceCategoryId(categoriesRes.data[0].id);
      }
    } catch (requestError) {
      setError(
        'Failed to load categories/services. Make sure backend is running.',
      );
      console.error(requestError);
    } finally {
      setIsLoading(false);
    }
  }

  async function loadBookings() {
    try {
      const res = await api.get<Booking[]>('/api/bookings/');
      setBookings(res.data);
    } catch (requestError) {
      console.error(requestError);
    }
  }

  async function handleLogin(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsAuthLoading(true);
    setError(null);
    try {
      const response = await api.post<LoginResponse>('/api/auth/login', {
        email,
        password,
      });
      if (response.data.user.role !== 'admin') {
        setError('Access denied. This panel requires an admin account.');
        return;
      }
      localStorage.setItem('token', response.data.access_token);
      localStorage.setItem('admin_user', JSON.stringify(response.data.user));
      setToken(response.data.access_token);
      setCurrentUser(response.data.user);
      await loadBookings();
    } catch (requestError) {
      setError('Login failed. Check credentials and backend.');
      console.error(requestError);
    } finally {
      setIsAuthLoading(false);
    }
  }

  function handleLogout() {
    localStorage.removeItem('token');
    localStorage.removeItem('admin_user');
    setToken(null);
    setCurrentUser(null);
    setBookings([]);
  }

  async function updateBookingStatus(bookingId: string, status: string) {
    try {
      await api.put(`/api/bookings/${bookingId}`, { status });
      await loadBookings();
      setNotice(`Booking status updated to ${status}`);
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to update booking status for this user role.');
    }
  }

  async function createCategory(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setNotice(null);
    try {
      await api.post('/api/services/categories', {
        name: categoryName,
        icon: categoryIcon || null,
        color_hex: categoryColor,
      });
      setCategoryName('');
      setCategoryIcon('');
      await loadPublicData();
      setNotice('Category created.');
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to create category. Login required.');
    }
  }

  async function toggleCategoryActive(category: Category) {
    setError(null);
    setNotice(null);
    try {
      await api.put(`/api/services/categories/${category.id}`, {
        is_active: !category.is_active,
      });
      await loadPublicData();
      setNotice('Category updated.');
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to update category.');
    }
  }

  async function deleteCategory(categoryId: string) {
    setError(null);
    setNotice(null);
    try {
      await api.delete(`/api/services/categories/${categoryId}`);
      await loadPublicData();
      setNotice('Category deactivated.');
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to delete category.');
    }
  }

  async function createService(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setNotice(null);
    try {
      await api.post('/api/services', {
        category_id: serviceCategoryId,
        name: serviceName,
        description: serviceDescription || null,
        min_price: Number(serviceMinPrice),
        max_price: Number(serviceMaxPrice),
        urgency_level: Number(serviceUrgency),
        is_active: true,
      });
      setServiceName('');
      setServiceDescription('');
      setServiceMinPrice('0');
      setServiceMaxPrice('0');
      setServiceUrgency('1');
      await loadPublicData();
      setNotice('Service created.');
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to create service. Login required.');
    }
  }

  async function toggleServiceActive(service: Service) {
    setError(null);
    setNotice(null);
    try {
      await api.put(`/api/services/${service.id}`, {
        is_active: !service.is_active,
      });
      await loadPublicData();
      setNotice('Service updated.');
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to update service.');
    }
  }

  async function deleteService(serviceId: string) {
    setError(null);
    setNotice(null);
    try {
      await api.delete(`/api/services/${serviceId}`);
      await loadPublicData();
      setNotice('Service deactivated.');
    } catch (requestError) {
      console.error(requestError);
      setError('Unable to delete service.');
    }
  }

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_10%_0%,#dbeafe_0%,#f8fafc_45%,#ffffff_100%)] px-6 py-8 text-slate-900">
      <div className="mx-auto max-w-7xl">
        <header className="mb-6 flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-sky-700">
              FixMate Control Center
            </p>
            <h1 className="mt-1 text-3xl font-semibold">Web Admin Panel</h1>
            <p className="text-sm text-slate-600">
              Manage categories, services, and live booking operations.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                void loadPublicData();
                if (token) {
                  void loadBookings();
                }
              }}
              className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium hover:bg-slate-100"
            >
              Refresh Data
            </button>
            {currentUser ? (
              <button
                onClick={handleLogout}
                className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700"
              >
                Logout
              </button>
            ) : null}
          </div>
        </header>

        {error ? (
          <p className="mb-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
            {error}
          </p>
        ) : null}
        {notice ? (
          <p className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {notice}
          </p>
        ) : null}

        <section className="mb-6 grid gap-4 md:grid-cols-4">
          <StatCard
            label="Categories"
            value={categories.length.toString()}
            tone="sky"
          />
          <StatCard
            label="Services"
            value={services.length.toString()}
            tone="indigo"
          />
          <StatCard
            label="Bookings"
            value={bookings.length.toString()}
            tone="amber"
          />
          <StatCard
            label="Completed Jobs"
            value={completedCount.toString()}
            tone="emerald"
          />
        </section>

        <section className="grid gap-6 lg:grid-cols-[340px_1fr]">
          <aside className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-xl font-semibold">Admin Login</h2>
            {currentUser ? (
              <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
                <p className="font-semibold">Signed in as {currentUser.name}</p>
                <p className="mt-1">{currentUser.email}</p>
                <p className="mt-1 capitalize">Role: {currentUser.role}</p>
                <p className="mt-3 text-xs text-emerald-700">
                  Bookings tab supports actions based on this role permissions.
                </p>
              </div>
            ) : (
              <form className="space-y-3" onSubmit={handleLogin}>
                <label className="block">
                  <span className="mb-1 block text-sm font-medium text-slate-700">
                    Email
                  </span>
                  <input
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none ring-sky-300 focus:ring"
                    placeholder="admin@fixmate.dev"
                    required
                  />
                </label>
                <label className="block">
                  <span className="mb-1 block text-sm font-medium text-slate-700">
                    Password
                  </span>
                  <input
                    type="password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none ring-sky-300 focus:ring"
                    placeholder="********"
                    required
                  />
                </label>
                <button
                  type="submit"
                  disabled={isAuthLoading}
                  className="w-full rounded-lg bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500 disabled:cursor-not-allowed disabled:opacity-70"
                >
                  {isAuthLoading ? 'Signing in...' : 'Sign In'}
                </button>
              </form>
            )}

            <div className="mt-5 rounded-xl border border-slate-200 bg-slate-50 p-3 text-xs text-slate-600">
              <p className="font-semibold text-slate-800">Admin Credentials</p>
              <p>Email: admin@fixmate.dev</p>
              <p>Password: Admin1234</p>
            </div>
          </aside>

          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <nav className="mb-4 flex flex-wrap gap-2">
              <TabButton
                active={activeTab === 'overview'}
                onClick={() => setActiveTab('overview')}
              >
                Overview
              </TabButton>
              <TabButton
                active={activeTab === 'categories'}
                onClick={() => setActiveTab('categories')}
              >
                Categories
              </TabButton>
              <TabButton
                active={activeTab === 'services'}
                onClick={() => setActiveTab('services')}
              >
                Services
              </TabButton>
              <TabButton
                active={activeTab === 'bookings'}
                onClick={() => setActiveTab('bookings')}
              >
                Bookings
              </TabButton>
            </nav>

            {isLoading ? (
              <p className="text-sm text-slate-600">Loading data...</p>
            ) : null}

            {!isLoading && activeTab === 'overview' ? (
              <div className="grid gap-3 md:grid-cols-2">
                <InfoCard
                  title="Active Categories"
                  value={`${categories.length}`}
                  subtitle="Current vehicle category set"
                />
                <InfoCard
                  title="Pending Bookings"
                  value={`${pendingCount}`}
                  subtitle="Requires technician action"
                />
                <InfoCard
                  title="Service Catalog"
                  value={`${services.length}`}
                  subtitle="Granular service tasks available"
                />
                <InfoCard
                  title="Completed Bookings"
                  value={`${completedCount}`}
                  subtitle="Finished jobs"
                />
              </div>
            ) : null}

            {!isLoading && activeTab === 'categories' ? (
              <div className="space-y-4">
                <form
                  onSubmit={createCategory}
                  className="grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4 md:grid-cols-4"
                >
                  <input
                    value={categoryName}
                    onChange={(event) => setCategoryName(event.target.value)}
                    placeholder="New category name"
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    required
                  />
                  <input
                    value={categoryIcon}
                    onChange={(event) => setCategoryIcon(event.target.value)}
                    placeholder="Icon (optional)"
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                  />
                  <input
                    type="color"
                    value={categoryColor}
                    onChange={(event) => setCategoryColor(event.target.value)}
                    className="h-10 rounded-lg border border-slate-300 bg-white"
                  />
                  <button className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700">
                    Add Category
                  </button>
                </form>

                <div className="grid gap-3 md:grid-cols-2">
                  {categories.map((category) => (
                    <div
                      key={category.id}
                      className="rounded-xl border border-slate-200 p-4"
                    >
                      <div className="mb-2 flex items-center justify-between">
                        <h3 className="text-lg font-semibold">
                          {category.name}
                        </h3>
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                          {category.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500">
                        Icon: {category.icon ?? '-'}
                      </p>
                      <p className="text-xs text-slate-500">
                        Color: {category.color_hex}
                      </p>
                      <div className="mt-3 flex gap-2">
                        <button
                          onClick={() => void toggleCategoryActive(category)}
                          className="rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-slate-100"
                        >
                          {category.is_active ? 'Deactivate' : 'Activate'}
                        </button>
                        <button
                          onClick={() => void deleteCategory(category.id)}
                          className="rounded-md bg-rose-600 px-2 py-1 text-xs font-medium text-white hover:bg-rose-500"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}

            {!isLoading && activeTab === 'services' ? (
              <div className="space-y-4">
                <form
                  onSubmit={createService}
                  className="grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4 md:grid-cols-6"
                >
                  <select
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    value={serviceCategoryId}
                    onChange={(event) =>
                      setServiceCategoryId(event.target.value)
                    }
                    required
                  >
                    {categories.map((category) => (
                      <option key={category.id} value={category.id}>
                        {category.name}
                      </option>
                    ))}
                  </select>
                  <input
                    value={serviceName}
                    onChange={(event) => setServiceName(event.target.value)}
                    placeholder="Service name"
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    required
                  />
                  <input
                    value={serviceDescription}
                    onChange={(event) =>
                      setServiceDescription(event.target.value)
                    }
                    placeholder="Description"
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                  />
                  <input
                    type="number"
                    min="0"
                    value={serviceMinPrice}
                    onChange={(event) => setServiceMinPrice(event.target.value)}
                    placeholder="Min"
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    required
                  />
                  <input
                    type="number"
                    min="0"
                    value={serviceMaxPrice}
                    onChange={(event) => setServiceMaxPrice(event.target.value)}
                    placeholder="Max"
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    required
                  />
                  <div className="flex gap-2">
                    <select
                      value={serviceUrgency}
                      onChange={(event) =>
                        setServiceUrgency(event.target.value)
                      }
                      className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    >
                      <option value="1">L1</option>
                      <option value="2">L2</option>
                      <option value="3">L3</option>
                    </select>
                    <button className="rounded-lg bg-slate-900 px-3 py-2 text-sm font-medium text-white hover:bg-slate-700">
                      Add
                    </button>
                  </div>
                </form>

                <div className="mb-3 flex flex-wrap items-center gap-2">
                  <label className="text-sm font-medium text-slate-700">
                    Filter by category
                  </label>
                  <select
                    className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                    value={selectedCategoryId}
                    onChange={(event) =>
                      setSelectedCategoryId(event.target.value)
                    }
                  >
                    <option value="all">All</option>
                    {categories.map((category) => (
                      <option key={category.id} value={category.id}>
                        {category.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="overflow-x-auto rounded-xl border border-slate-200">
                  <table className="w-full text-left text-sm">
                    <thead className="bg-slate-50 text-slate-700">
                      <tr>
                        <th className="px-3 py-2">Name</th>
                        <th className="px-3 py-2">Price Range</th>
                        <th className="px-3 py-2">Urgency</th>
                        <th className="px-3 py-2">Status</th>
                        <th className="px-3 py-2">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredServices.map((service) => (
                        <tr
                          key={service.id}
                          className="border-t border-slate-100"
                        >
                          <td className="px-3 py-2">
                            <p className="font-medium">{service.name}</p>
                            <p className="text-xs text-slate-500">
                              {service.description ?? 'No description'}
                            </p>
                          </td>
                          <td className="px-3 py-2">
                            ${service.min_price} - ${service.max_price}
                          </td>
                          <td className="px-3 py-2">
                            L{service.urgency_level}
                          </td>
                          <td className="px-3 py-2">
                            {service.is_active ? 'Active' : 'Inactive'}
                          </td>
                          <td className="px-3 py-2">
                            <div className="flex gap-2">
                              <button
                                onClick={() =>
                                  void toggleServiceActive(service)
                                }
                                className="rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-slate-100"
                              >
                                {service.is_active ? 'Deactivate' : 'Activate'}
                              </button>
                              <button
                                onClick={() => void deleteService(service.id)}
                                className="rounded-md bg-rose-600 px-2 py-1 text-xs font-medium text-white hover:bg-rose-500"
                              >
                                Delete
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ) : null}

            {!isLoading && activeTab === 'bookings' ? (
              <div>
                {!token ? (
                  <p className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
                    Sign in to load and manage bookings.
                  </p>
                ) : bookings.length === 0 ? (
                  <p className="text-sm text-slate-600">
                    No bookings for this account.
                  </p>
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-200">
                    <table className="w-full text-left text-sm">
                      <thead className="bg-slate-50 text-slate-700">
                        <tr>
                          <th className="px-3 py-2">Booking</th>
                          <th className="px-3 py-2">Address</th>
                          <th className="px-3 py-2">Schedule</th>
                          <th className="px-3 py-2">Status</th>
                          <th className="px-3 py-2">Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {bookings.map((booking) => (
                          <tr
                            key={booking.id}
                            className="border-t border-slate-100"
                          >
                            <td className="px-3 py-2 font-medium">
                              {booking.id.slice(0, 8)}
                            </td>
                            <td className="px-3 py-2">{booking.address}</td>
                            <td className="px-3 py-2">
                              {new Date(booking.scheduled_at).toLocaleString()}
                            </td>
                            <td className="px-3 py-2">
                              <span
                                className={`rounded-full border px-2 py-1 text-xs font-medium ${statusClass[booking.status] ?? 'bg-slate-100 text-slate-700 border-slate-200'}`}
                              >
                                {booking.status}
                              </span>
                            </td>
                            <td className="px-3 py-2">
                              {booking.status !== 'cancelled' &&
                              booking.status !== 'completed' ? (
                                <div className="flex gap-2">
                                  <button
                                    onClick={() =>
                                      void updateBookingStatus(
                                        booking.id,
                                        'in_progress',
                                      )
                                    }
                                    className="rounded-md bg-indigo-600 px-2 py-1 text-xs font-medium text-white hover:bg-indigo-500"
                                  >
                                    In Progress
                                  </button>
                                  <button
                                    onClick={() =>
                                      void updateBookingStatus(
                                        booking.id,
                                        'completed',
                                      )
                                    }
                                    className="rounded-md bg-emerald-600 px-2 py-1 text-xs font-medium text-white hover:bg-emerald-500"
                                  >
                                    Complete
                                  </button>
                                </div>
                              ) : (
                                <span className="text-xs text-slate-400">
                                  No actions
                                </span>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            ) : null}
          </section>
        </section>
      </div>
    </main>
  );
}

function TabButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={`rounded-lg px-3 py-2 text-sm font-medium transition ${
        active
          ? 'bg-slate-900 text-white'
          : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-100'
      }`}
    >
      {children}
    </button>
  );
}

function StatCard({
  label,
  value,
  tone,
}: {
  label: string;
  value: string;
  tone: 'sky' | 'indigo' | 'amber' | 'emerald';
}) {
  const toneClass = {
    sky: 'border-sky-200 bg-sky-50 text-sky-900',
    indigo: 'border-indigo-200 bg-indigo-50 text-indigo-900',
    amber: 'border-amber-200 bg-amber-50 text-amber-900',
    emerald: 'border-emerald-200 bg-emerald-50 text-emerald-900',
  }[tone];

  return (
    <article className={`rounded-xl border p-4 ${toneClass}`}>
      <p className="text-xs font-semibold uppercase tracking-wide opacity-80">
        {label}
      </p>
      <p className="mt-2 text-3xl font-semibold">{value}</p>
    </article>
  );
}

function InfoCard({
  title,
  value,
  subtitle,
}: {
  title: string;
  value: string;
  subtitle: string;
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <p className="text-sm text-slate-500">{title}</p>
      <p className="mt-1 text-2xl font-semibold text-slate-900">{value}</p>
      <p className="mt-1 text-xs text-slate-500">{subtitle}</p>
    </div>
  );
}
