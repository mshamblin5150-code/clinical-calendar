export const placements = [
  {
    id: 'family', name: 'Family Medicine', completed: 126, scheduled: 108, target: 270, reviewCadence: 90, evaluationPlan: { initialSelf: true, finalSelf: true, finalPlacement: true }, icon: 'stethoscope',
    preceptors: [
      { id: 'smith', name: 'Dr. Smith', primary: true, completed: 96, scheduled: 72 },
      { id: 'nguyen', name: 'Dr. Nguyen', primary: false, completed: 30, scheduled: 36 },
    ],
  },
  { id: 'internal', name: 'Internal Medicine', completed: 0, scheduled: 0, target: 240, reviewCadence: 90, evaluationPlan: { initialSelf: true, finalSelf: true, finalPlacement: true }, icon: 'activity', preceptors: [{ id: 'patel', name: 'Dr. Patel', primary: true, completed: 0, scheduled: 0 }] },
  { id: 'pediatrics', name: 'Pediatrics', completed: 0, scheduled: 0, target: 120, reviewCadence: 90, evaluationPlan: { initialSelf: true, finalSelf: true, finalPlacement: true }, icon: 'sparkles', preceptors: [{ id: 'lee', name: 'Dr. Lee', primary: true, completed: 0, scheduled: 0 }] },
  { id: 'billing', name: 'Billing & Coding', completed: 0, scheduled: 0, target: 90, reviewCadence: 90, evaluationPlan: { initialSelf: true, finalSelf: true, finalPlacement: true }, icon: 'file', preceptors: [{ id: 'jones', name: 'A. Jones', primary: true, completed: 0, scheduled: 0 }] },
];

export const calendarWeeks = [
  [
    { day: 26, outside: true }, { day: 27, outside: true }, { day: 28, outside: true },
    { day: 29, outside: true }, { day: 30, outside: true }, { day: 31, outside: true },
    { day: 1, event: { time: '08:00–16:00', label: 'Cardiology Clinic', type: 'clinical' } },
  ],
  [
    { day: 2 }, { day: 3, event: { time: '07:00–15:00', label: 'Work Shift', type: 'work' } },
    { day: 4, event: { time: '07:00–15:30', label: 'Surgery – OR', type: 'clinical' } },
    { day: 5, event: { time: '15:00–23:00', label: 'Work Shift', type: 'work' } },
    { day: 6, event: { time: '08:00–16:00', label: 'Family Med Clinic', type: 'clinical' } },
    { day: 7 }, { day: 8, protected: true },
  ],
  [
    { day: 9 }, { day: 10, event: { time: '07:00–15:00', label: 'Work Shift', type: 'work' } },
    { day: 11, event: { time: '12:00–20:00', label: 'Pediatrics Clinic', type: 'clinical' } },
    { day: 12, event: { time: '15:00–23:00', label: 'Work Shift', type: 'work' } },
    { day: 13 }, { day: 14, event: { time: '07:00–15:30', label: 'OB Clinic', type: 'clinical' } }, { day: 15 },
  ],
  [
    { day: 16, selected: true },
    { day: 17, event: { time: '07:00–15:00', label: 'Work Shift', type: 'work' } },
    { day: 18, selected: true },
    { day: 19, event: { time: '08:00–16:00', label: 'Internal Med', type: 'clinical' } },
    { day: 20, event: { time: '15:00–23:00', label: 'Work Shift', type: 'work' } },
    { day: 21 }, { day: 22, event: { time: '07:00–15:30', label: 'Surgery – Clinic', type: 'clinical' } },
  ],
  [
    { day: 23 }, { day: 24 },
    { day: 25, event: { time: '12:00–20:00', label: 'Pediatrics Clinic', type: 'clinical' } },
    { day: 26 }, { day: 27, selected: true },
    { day: 28, event: { time: '07:00–15:00', label: 'Work Shift', type: 'work' } }, { day: 29 },
  ],
  [
    { day: 30 }, { day: 31, event: { time: '07:00–15:00', label: 'Work Shift', type: 'work' } },
    { day: 1, outside: true }, { day: 2, outside: true }, { day: 3, outside: true },
    { day: 4, outside: true }, { day: 5, outside: true },
  ],
];

export const defaultSelectedDates = new Set(['16', '18', '27', '28']);
