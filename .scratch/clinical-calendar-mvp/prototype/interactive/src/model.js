const pad = (value) => String(value).padStart(2, '0');

export const templateTimes = {
  'Day Shift': '07:00-19:00',
  'Evening Shift': '11:00-23:00',
};

export const initialCommitments = [
  { id: 'work-03', date: '2026-08-03', time: '07:00-19:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-05', date: '2026-08-05', time: '11:00-23:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-10', date: '2026-08-10', time: '07:00-19:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-12', date: '2026-08-12', time: '11:00-23:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-17', date: '2026-08-17', time: '07:00-19:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-20', date: '2026-08-20', time: '11:00-23:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-28', date: '2026-08-28', time: '07:00-19:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'work-31', date: '2026-08-31', time: '07:00-19:00', label: 'Work Shift', type: 'work', status: 'scheduled', hours: 12 },
  { id: 'family-01', date: '2026-08-01', time: '07:00-19:00', label: 'Family Medicine - Dr. Nguyen', type: 'clinical', status: 'awaiting-confirmation', hours: 12, placementId: 'family', preceptorId: 'nguyen' },
  { id: 'family-06', date: '2026-08-06', time: '07:00-19:00', label: 'Family Medicine - Dr. Smith', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'family', preceptorId: 'smith' },
  { id: 'family-14', date: '2026-08-14', time: '07:00-19:00', label: 'Family Medicine - Dr. Smith', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'family', preceptorId: 'smith' },
  { id: 'family-22', date: '2026-08-22', time: '07:00-19:00', label: 'Family Medicine - Dr. Nguyen', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'family', preceptorId: 'nguyen' },
  { id: 'internal-19', date: '2026-08-19', time: '07:00-19:00', label: 'Internal Medicine - Dr. Patel', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'internal', preceptorId: 'patel' },
  { id: 'peds-11', date: '2026-08-11', time: '07:00-19:00', label: 'Pediatrics - Dr. Lee', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'pediatrics', preceptorId: 'lee' },
  { id: 'peds-25', date: '2026-08-25', time: '07:00-19:00', label: 'Pediatrics - Dr. Lee', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'pediatrics', preceptorId: 'lee' },
  ...[1, 3, 5, 7, 9].map((day) => ({ id: `family-sep-${day}`, date: `2026-09-${pad(day)}`, time: '07:00-19:00', label: 'Family Medicine - Dr. Smith', type: 'clinical', status: 'scheduled', hours: 12, placementId: 'family', preceptorId: 'smith' })),
];

export const isActiveCommitment = (commitment) => commitment.status === 'scheduled' || commitment.status === 'awaiting-confirmation';

export function monthCells(anchor) {
  const year = anchor.getFullYear();
  const month = anchor.getMonth();
  const firstDay = new Date(year, month, 1);
  const gridStart = new Date(year, month, 1 - firstDay.getDay());
  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index);
    return {
      date,
      iso: `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`,
      day: date.getDate(),
      outside: date.getMonth() !== month,
    };
  });
}

export function weekDates(anchor) {
  const start = new Date(anchor.getFullYear(), anchor.getMonth(), anchor.getDate() - anchor.getDay());
  return Array.from({ length: 7 }, (_, index) => {
    const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
    return { date, iso: `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`, day: date.getDate() };
  });
}

export function movePeriod(anchor, view, direction) {
  const next = new Date(anchor);
  if (view === 'Week') next.setDate(next.getDate() + (7 * direction));
  else next.setMonth(next.getMonth() + direction, 1);
  return next;
}

export function periodTitle(anchor, view) {
  if (view !== 'Week') return anchor.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  const dates = weekDates(anchor);
  const first = dates[0].date;
  const last = dates[6].date;
  const sameMonth = first.getMonth() === last.getMonth();
  return sameMonth
    ? `${first.toLocaleDateString('en-US', { month: 'short' })} ${first.getDate()}-${last.getDate()}, ${last.getFullYear()}`
    : `${first.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${last.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}, ${last.getFullYear()}`;
}

export function derivePlacementMetrics(placements, commitments) {
  return placements.map((placement) => {
    const clinical = commitments.filter((commitment) => commitment.type === 'clinical' && commitment.placementId === placement.id);
    const completedFromSessions = clinical.filter((commitment) => commitment.status === 'completed').reduce((sum, commitment) => sum + commitment.hours, 0);
    const scheduled = clinical.filter(isActiveCommitment).reduce((sum, commitment) => sum + commitment.hours, 0);
    const completed = placement.completed + completedFromSessions;
    return {
      ...placement,
      completed,
      scheduled,
      remaining: Math.max(placement.target - completed, 0),
      unscheduled: Math.max(placement.target - completed - scheduled, 0),
      overTarget: Math.max(completed - placement.target, 0),
      preceptors: placement.preceptors.map((preceptor) => {
        const supervised = clinical.filter((commitment) => commitment.preceptorId === preceptor.id);
        return {
          ...preceptor,
          completed: preceptor.completed + supervised.filter((commitment) => commitment.status === 'completed').reduce((sum, commitment) => sum + commitment.hours, 0),
          scheduled: supervised.filter(isActiveCommitment).reduce((sum, commitment) => sum + commitment.hours, 0),
        };
      }),
    };
  });
}
