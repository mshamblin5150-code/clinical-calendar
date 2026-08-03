import { useEffect, useMemo, useState } from 'react';
import {
  Activity, Bell, CalendarDays, Check, ChevronDown, ChevronLeft, ChevronRight,
  CircleAlert, CircleHelp, Clock3, FileClock, Menu, Plus, Settings, Sparkles, Stethoscope,
  Trash2, UserRound, UsersRound, X,
} from 'lucide-react';
import { placements as initialPlacements } from './data.js';
import { derivePlacementMetrics, initialCommitments, isActiveCommitment, monthCells, movePeriod, periodTitle, templateTimes, weekDates } from './model.js';
import { CommitmentModal, defaultTemplates, PlacementSettings, PlanningTray, SettingsModal } from './EnhancedPanels.jsx';

const icons = { stethoscope: Stethoscope, activity: Activity, sparkles: Sparkles, file: FileClock };
const initialEvaluations = [
  { id: 'initial-self', label: 'Initial self-assessment', detail: 'Before placement', status: 'Documented' },
  { id: 'interim-90-student', label: '90 hr - your review of Primary Preceptor', detail: 'Medatrax', status: 'Documented' },
  { id: 'interim-90-primary', label: '90 hr - Primary Preceptor review of you', detail: 'Medatrax', status: 'Documented' },
  { id: 'interim-180-student', label: '180 hr - your review of Primary Preceptor', detail: 'Approaching', status: 'Not documented', current: true },
  { id: 'interim-180-primary', label: '180 hr - Primary Preceptor review of you', detail: 'Approaching', status: 'Not documented', current: true },
  { id: 'final-self', label: 'Final self-assessment', detail: 'At placement completion', status: 'Not documented' },
  { id: 'final-placement', label: 'Final clinical placement review', detail: 'At placement completion', status: 'Not documented' },
];
const evaluationRequirementById = { 'initial-self':'initialSelf', 'final-self':'finalSelf', 'final-placement':'finalPlacement' };
const themeHelpGuides = {
  'Borg Tactical Console': {
    summary:'Industrial Collective visual language using dark cybernetic structure, green illumination, and sparse signal colors.',
    states:[
      ['Clinical Sessions','Collective green; these sessions count toward a Clinical Placement.'],
      ['Work Shifts','Gunmetal and muted teal; these reserve work time but do not change clinical hours.'],
      ['Protected Days','Striped graphite and regeneration silver; these block the entire day for yourself.'],
      ['Today','An optic-red date badge and inset outline, layered over any other day state.'],
    ],
  },
};
const clonePlacements = () => initialPlacements.map((p) => ({ ...p, preceptors: p.preceptors.map((x) => ({ ...x })) }));
const prettyDate = (iso, compact = false) => new Date(`${iso}T12:00:00`).toLocaleDateString('en-US', compact ? { month: 'short', day: 'numeric' } : { weekday: 'short', month: 'short', day: 'numeric' });
const isCalendarCommitment = (commitment) => commitment.status !== 'cancelled' && commitment.status !== 'missed';
const formatClock = (value, preference) => {
  if (preference === 'Military time' || value === 'All day') return value;
  const [hour,minute] = value.split(':').map(Number);
  return `${hour % 12 || 12}:${String(minute).padStart(2,'0')} ${hour >= 12 ? 'PM' : 'AM'}`;
};
const formatCommitmentTime = (range, preference) => range === 'All day' ? range : range.split('-').map((value) => formatClock(value,preference)).join('-');

function Toast({ message, nonce }) {
  const [phase, setPhase] = useState('in');
  useEffect(() => {
    setPhase('in');
    const fly = setTimeout(() => setPhase('out'), 3500);
    return () => clearTimeout(fly);
  }, [message, nonce]);
  if (!message) return null;
  return <div className={`prototype-toast ${phase}`} role="status"><Check size={15} />{message}</div>;
}

const initialsFromName = (name) => name.trim().split(/\s+/).filter(Boolean).slice(0,2).map((part) => part[0]).join('').toUpperCase() || '?';

function Header({ count, open, onAdd, profile }) {
  return <header className="top-command">
    <button className="brand brand-button" onClick={() => open('menu')}><Menu size={23} /><span>Clinical Calendar</span></button>
    <button className="mobile-help-button" onClick={() => open('help')} aria-label="Help"><CircleHelp/></button>
    <button className="avatar mobile-profile-button" onClick={() => open('profile')} aria-label="Student profile">{profile.photo ? <img src={profile.photo} alt=""/> : profile.initials}</button>
    <div className="top-actions">
      <button className="add-button" onClick={onAdd}><Plus size={18} /> Add schedule</button>
      <button className="help-button" onClick={() => open('help')}><CircleHelp size={18}/> Help</button>
      <button className="notification-button" onClick={() => open('notifications')} aria-label={`Notifications, ${count} unresolved`}><Bell size={19} />{count ? <b>{count}</b> : null}</button>
      <span className="sync-status"><Check size={14} /> Synced</span>
      <button className="avatar" onClick={() => open('profile')} aria-label="Student profile">{profile.photo ? <img src={profile.photo} alt=""/> : profile.initials}</button>
    </div>
  </header>;
}

function TotalProgress({ placements, className = '' }) {
  const completed = placements.reduce((n, p) => n + p.completed, 0);
  const target = placements.reduce((n, p) => n + p.target, 0);
  const percent = target ? Math.min(100, Math.round(completed / target * 100)) : 0;
  return <section className={`total-progress ${className}`} aria-label={`Total progress, ${completed} of ${target} hours completed, ${percent} percent`}><span>Total progress</span><small>{completed} / {target} completed ({percent}%)</small><span className="segmented-progress dynamic">{Array.from({length:8},(_,index) => { const fill=Math.max(0,Math.min(100,(percent-index*12.5)*8)); return <i style={{background:`linear-gradient(to right, var(--green) ${fill}%, #2a2e29 ${fill}%)`}} key={index}/>; })}</span></section>;
}

function PlacementDock({ placements, selected, onSelect, onSettings }) {
  return <aside className="placement-dock tactical-panel">
    <button className="dock-heading" onClick={onSettings}><span>My placements</span><Settings size={15} /></button>
    <div className="placement-list">{placements.map((p) => {
      const Icon = icons[p.icon] || Stethoscope;
      const pct = p.target ? Math.min(100, Math.round(p.completed / p.target * 100)) : 0;
      return <button className={`placement-row ${selected === p.id ? 'active' : ''}`} key={p.id} onClick={() => onSelect(p.id)}>
        <span className="placement-icon"><Icon size={21} /></span><span className="placement-copy"><strong>{p.name}</strong><small>{p.completed} / {p.target} completed ({pct}%)</small><small>{p.scheduled} scheduled · {p.unscheduled} unscheduled</small><span className="mini-progress"><i style={{ width: `${pct}%` }} /></span></span><span className="status-pip" />
      </button>;
    })}</div>
    <TotalProgress placements={placements}/>
  </aside>;
}

function ProgressDonut({ placement, onNext, touch = false }) {
  const [details, setDetails] = useState(false);
  const denominator = Math.max(placement.target, 1);
  const completedEnd = Math.min(100, placement.completed / denominator * 100);
  const scheduledEnd = Math.min(100, (placement.completed + placement.scheduled) / denominator * 100);
  const background = `conic-gradient(var(--borg-completed) 0 ${completedEnd}%, var(--borg-scheduled) ${completedEnd}% ${scheduledEnd}%, var(--borg-unscheduled) ${scheduledEnd}% 100%)`;
  return <section className="progress-panel tactical-panel">
    <header><strong>{placement.name}</strong><span className="status-pip" /></header>
    <div className="progress-content"><button className="donut donut-button" style={{ background }} onClick={onNext} aria-label={`Show next Clinical Placement after ${placement.name}`}><div><strong>{placement.completed} hr</strong><span>completed</span></div></button>
      <ul><li><i className="target" /><span>Target</span><b>{placement.target} hr</b></li><li><i className="completed" /><span>Completed</span><b>{placement.completed} hr</b></li><li><i className="scheduled" /><span>Scheduled</span><b>{placement.scheduled} hr</b></li><li><i className="unscheduled" /><span>Unscheduled</span><b>{placement.unscheduled} hr</b></li>{placement.overTarget ? <li><i className="warning" /><span>Over target</span><b>{placement.overTarget} hr</b></li> : null}</ul>
    </div>
    <button className="text-action wheel-hint" onClick={onNext}>{touch ? 'Tap' : 'Click'} wheel to view next placement</button><button className="text-action" onClick={() => setDetails(!details)}>{details ? 'Hide' : 'Show'} preceptor breakdown</button>
    {details ? <div className="preceptor-breakdown">{placement.preceptors.map((p) => <div key={p.id}><span><strong>{p.name}</strong>{p.primary ? <small>Primary</small> : null}</span><b>{p.completed} completed / {p.scheduled} scheduled</b></div>)}</div> : null}
  </section>;
}

function CalendarGrid({ anchor, commitments, protectedDates, selectedDates, onDay, compact = false, timeDisplay = 'Military time' }) {
  const headers = compact ? ['S','M','T','W','T','F','S'] : ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  const now = new Date();
  const todayIso = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`;
  return <div className={`calendar-grid ${compact ? 'compact' : ''}`}>{headers.map((h, i) => <div className="weekday" key={`${h}-${i}`}>{h}</div>)}
    {monthCells(anchor).map((cell) => {
      const event = commitments.find((c) => c.date === cell.iso && isCalendarCommitment(c));
      const protectedDay = protectedDates.has(cell.iso);
      const selected = selectedDates.has(cell.iso);
      const today = cell.iso === todayIso;
      return <button key={cell.iso} className={`day-cell ${cell.outside ? 'outside' : ''} ${today ? 'today' : ''} ${selected ? 'selected' : ''} ${event?.type === 'work' ? 'work-day' : ''} ${protectedDay ? 'protected' : ''}`} onClick={() => onDay(cell.iso)} title={selected ? 'Click to remove this date from the batch' : undefined} aria-label={`${prettyDate(cell.iso)}${today ? ', Today' : ''}${event ? `, ${event.label}` : ''}${protectedDay ? ', Protected Day' : ''}${selected ? ', Selected; click to deselect' : ''}`}>
        <span className="day-number">{cell.day}</span>{selected ? <span className="selected-check"><Check size={compact ? 9 : 12} /></span> : null}
        {protectedDay ? <span className="protected-label">Protected Day</span> : null}
        {event ? compact ? <span className={`event-dot ${event.type}`} /> : <span className={`calendar-event ${event.type} ${event.status === 'completed' ? 'completed-event' : ''}`}><small>{formatCommitmentTime(event.time,timeDisplay)} · {event.hours} hr</small>{event.label}{event.status === 'completed' ? <em>Completed</em>:null}</span> : null}
      </button>;
    })}
  </div>;
}

function WeekView({ anchor, commitments, protectedDates, onDay, timeDisplay = 'Military time' }) {
  return <div className="alternate-view week-view">{weekDates(anchor).map((d) => {
    const rows = commitments.filter((c) => c.date === d.iso && isCalendarCommitment(c));
    return <article key={d.iso}><button onClick={() => onDay(d.iso)}><strong>{prettyDate(d.iso, true)}</strong></button>{protectedDates.has(d.iso) ? <button className="week-protected" onClick={() => onDay(d.iso)}>Protected Day</button> : null}{rows.map((c) => <button className={`week-event ${c.type}`} onClick={() => onDay(d.iso)} key={c.id}><b>{formatCommitmentTime(c.time,timeDisplay)}</b>{c.label}</button>)}{!rows.length && !protectedDates.has(d.iso) ? <small>Open day</small> : null}</article>;
  })}</div>;
}

function AgendaView({ anchor, commitments, protectedDates, onDay, timeDisplay = 'Military time' }) {
  const cells = monthCells(anchor).filter((c) => !c.outside);
  const rows = cells.flatMap((d) => [...(protectedDates.has(d.iso) ? [{ id: `p-${d.iso}`, date: d.iso, time: 'All day', label: 'Protected Day', type:'protected' }] : []), ...commitments.filter((c) => c.date === d.iso && isCalendarCommitment(c))]);
  return <div className="alternate-view agenda-view">{rows.length ? rows.map((row) => <button className={`agenda-row ${row.type}`} onClick={() => onDay(row.date)} key={row.id}><strong>{prettyDate(row.date, true)}</strong><b>{formatCommitmentTime(row.time,timeDisplay)}</b><span>{row.label}</span></button>) : <div className="empty-state">No commitments in this month.</div>}</div>;
}

function LegacyPlanningTray({ placements, selectedPlacement, selectedDates, conflicts, expanded, setExpanded, onRemoveConflicts, onApply }) {
  const [stage, setStage] = useState(0);
  const [kind, setKind] = useState('Clinical Session');
  const [template, setTemplate] = useState('Day Shift');
  const [placementId, setPlacementId] = useState(selectedPlacement);
  const placement = placements.find((p) => p.id === placementId) || placements[0];
  const primary = placement.preceptors.find((p) => p.primary) || placement.preceptors[0];
  const [preceptorId, setPreceptorId] = useState(primary?.id || '');
  const changePlacement = (id) => { const next = placements.find((p) => p.id === id); setPlacementId(id); setPreceptorId((next.preceptors.find((p) => p.primary) || next.preceptors[0])?.id || ''); };
  const apply = () => { onApply({ dates: [...selectedDates], kind, template, placementId, preceptorId }); setStage(0); setExpanded(false); };
  return <section className={`planning-tray tactical-panel ${expanded ? 'expanded' : 'collapsed'}`}>
    <div className="tray-summary"><span><strong>{selectedDates.size} dates selected</strong><i />{kind}<i />{template}<i className={conflicts.length ? 'danger-dot' : ''} />{conflicts.length ? `${conflicts.length} conflict` : 'Ready'}</span><div><button className="icon-button" onClick={() => setExpanded(!expanded)}><ChevronDown className={expanded ? '' : 'rotate'} /></button><button onClick={() => setExpanded(true)}>Expand</button><button className="primary" onClick={() => { setExpanded(true); setStage(2); }}>Review</button></div></div>
    {expanded ? <div className="tray-body"><div className="stage-tabs">{['Template','Placement','Review'].map((name, i) => <button className={stage === i ? 'active' : ''} key={name} onClick={() => setStage(i)}><span>{i+1}</span><b>{name}</b><small>{i === 0 ? 'Choose 12-hour template' : i === 1 ? 'Choose placement and preceptor' : 'Resolve every conflict'}</small></button>)}</div>
      <div className="stage-content">{stage === 0 ? <div className="form-stage two-field-stage"><label>Commitment<select value={kind} onChange={(e) => setKind(e.target.value)}><option>Clinical Session</option><option>Work Shift</option></select></label><label>12-hour template<select value={template} onChange={(e) => setTemplate(e.target.value)}>{Object.keys(templateTimes).map((x) => <option key={x}>{x}</option>)}</select></label><div className="date-chips">{[...selectedDates].map((d) => <span key={d}>{prettyDate(d, true)}</span>)}</div></div> : null}
      {stage === 1 ? <div className="form-stage two-field-stage">{kind === 'Clinical Session' ? <><label>Placement<select value={placementId} onChange={(e) => changePlacement(e.target.value)}>{placements.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}</select></label><label>Preceptor<select value={preceptorId} onChange={(e) => setPreceptorId(e.target.value)}>{placement.preceptors.map((p) => <option key={p.id} value={p.id}>{p.name}{p.primary ? ' - Primary' : ''}</option>)}</select></label></> : null}<div className="impact"><span>Applies to</span><strong>{selectedDates.size} dates · {templateTimes[template]}</strong><small>{kind === 'Clinical Session' ? `+${selectedDates.size * 12} Scheduled Hours` : 'Work Shifts do not change Clinical Placement hours.'}</small></div></div> : null}
      {stage === 2 ? <div className={`conflict-review ${conflicts.length ? '' : 'resolved'}`}>{conflicts.length ? <CircleAlert /> : <Check />}<span><strong>{conflicts.length ? 'Batch cannot be applied' : 'Batch is valid'}</strong><small>{conflicts.length ? `${conflicts.map((d) => prettyDate(d, true)).join(', ')} already contain a commitment or Protected Day.` : `${selectedDates.size} commitments will be added.`}</small></span>{conflicts.length ? <button onClick={onRemoveConflicts}>Remove conflicting dates</button> : <b>Ready</b>}</div> : null}</div>
      <div className="tray-actions"><button onClick={() => setStage(Math.max(0, stage-1))} disabled={!stage}>Back</button><button className="primary" onClick={stage === 2 ? apply : () => setStage(stage+1)} disabled={stage === 2 && (!selectedDates.size || conflicts.length)}>{stage === 2 ? 'Apply schedule' : 'Next'}</button></div>
    </div> : null}
  </section>;
}

function Evaluations({ evaluations, onDocument, onClose, cadence = 90 }) {
  const cadenceLabel = (evaluation) => evaluation.label.replace(/^90 hr/, `${cadence} hr`).replace(/^180 hr/, `${cadence * 2} hr`);
  return <section className="evaluation-panel tactical-panel"><header><strong>Evaluation plan · every {cadence} Completed Hours</strong><button className="icon-button" onClick={onClose}><X /></button></header>{evaluations.map((e) => <div className="evaluation-row" key={e.id}><span><strong>{cadenceLabel(e)}</strong><small>{e.detail}</small></span>{e.status === 'Documented' ? <b className="documented"><Check /> Documented</b> : <button onClick={() => onDocument(e.id)}>Document</button>}</div>)}</section>;
}

function EvaluationModal({ evaluations, onDocument, onClose, onBack, cadence = 90 }) {
  const cadenceLabel = (evaluation) => evaluation.label.replace(/^90 hr/, `${cadence} hr`).replace(/^180 hr/, `${cadence * 2} hr`);
  return <Modal title="Evaluation plan" onClose={onClose} onBack={onBack}><div className="evaluation-modal-list">{evaluations.map((evaluation) => <div className="evaluation-row" key={evaluation.id}><span><strong>{cadenceLabel(evaluation)}</strong><small>{evaluation.detail}</small></span>{evaluation.status === 'Documented' ? <b className="documented"><Check/> Documented</b> : <button onClick={() => onDocument(evaluation.id)}>Document</button>}</div>)}</div></Modal>;
}

function InterimCard({ pending, onView }) {
  return pending ? <section className="interim-warning tactical-panel"><CircleAlert size={38}/><strong>Interim review<br/>approaching</strong><p>{pending} required review {pending === 1 ? 'item is' : 'items are'} not documented.</p><button onClick={onView}>View evaluations</button></section> : <section className="interim-clear tactical-panel"><Check size={28}/><span><strong>Evaluations up to date</strong><small>Current Interim Review is documented.</small></span></section>;
}

function Attention({ awaiting, planningIncomplete, onConfirm, onPlan }) {
  return <section className="attention-panel tactical-panel"><h2>Needs attention <span className="status-pip" /></h2>{awaiting ? <button className="attention-row" onClick={onConfirm}><span className="round-icon danger"><CalendarDays /></span><span><strong>{awaiting} needs confirmation</strong><small>Confirm, correct, cancel, or mark missed.</small></span><ChevronRight /></button> : <div className="attention-resolved"><Check /> Past sessions are confirmed.</div>}{planningIncomplete ? <button className="attention-row" onClick={onPlan}><span className="round-icon warning"><Clock3 /></span><span><strong>Planning incomplete</strong><small>Choose Protected Days for displayed weeks.</small></span><ChevronRight /></button> : <div className="attention-resolved"><Check /> Displayed weeks have Protected Days.</div>}</section>;
}

function Modal({ title, onClose, onBack, children, wide = false }) {
  return <div className="modal-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}><section className={`modal tactical-panel ${wide ? 'wide' : ''}`} role="dialog" aria-modal="true" aria-label={title}><header>{onBack ? <button className="modal-back" onClick={onBack}>Back</button> : null}<h2>{title}</h2><button className="icon-button" onClick={onClose} aria-label="Close"><X /></button></header>{children}</section></div>;
}

function LegacyCommitmentModal({ commitment, placements, onAction, onClose }) {
  const placement = placements.find((p) => p.id === commitment.placementId);
  const preceptor = placement?.preceptors.find((p) => p.id === commitment.preceptorId);
  return <Modal title={commitment.type === 'clinical' ? 'Clinical Session' : 'Work Shift'} onClose={onClose}><div className="detail-stack"><strong>{prettyDate(commitment.date)}</strong><span>{commitment.time} · 12 hours</span>{placement ? <span>{placement.name} · {preceptor?.name}</span> : null}<span className="status-chip">{commitment.status.replace('-', ' ')}</span></div><div className="modal-actions">{commitment.status === 'awaiting-confirmation' ? <button className="primary" onClick={() => onAction('completed')}>Confirm 12 completed hours</button> : null}{commitment.type === 'clinical' && isActiveCommitment(commitment) ? <><button onClick={() => onAction('cancelled')}>Cancel session</button><button onClick={() => onAction('missed')}>Mark missed</button></> : null}<button className="danger-action" onClick={() => onAction('delete')}><Trash2 /> Delete erroneous entry</button></div></Modal>;
}

function ProtectedModal({ date, onRemove, onMove, onClose }) { return <Modal title="Protected Day" onClose={onClose}><div className="detail-stack"><strong>{prettyDate(date)}</strong><span>Blocked for yourself and preparation for the week ahead.</span></div><div className="modal-actions"><button className="primary" onClick={onMove}>Move to another day</button><button className="danger-action" onClick={onRemove}><Trash2 /> Remove Protected Day</button></div></Modal>; }

function NotificationModal({ notices, onOpen, onClose, onBack }) { return <Modal title="Notifications" onClose={onClose} onBack={onBack}>{notices.length ? <div className="notification-list">{notices.map((n) => <button key={n.id} onClick={() => onOpen(n)}><span className={`round-icon ${n.tone}`}><n.Icon /></span><span><strong>{n.title}</strong><small>{n.detail}</small></span><ChevronRight /></button>)}</div> : <div className="empty-state"><Check /> You are all caught up.</div>}</Modal>; }

function ProfileModal({ profile, setProfile, onClose, onBack, notify }) {
  const [draft, setDraft] = useState(profile);
  const changeName = (name) => setDraft({...draft,name,initials:initialsFromName(name)});
  const choosePhoto = (event) => { const file = event.target.files?.[0]; if (!file) return; const reader = new FileReader(); reader.onload = () => setDraft((current) => ({...current,photo:reader.result})); reader.readAsDataURL(file); };
  return <Modal title="Student profile" onClose={onClose} onBack={onBack}><div className="modal-form"><div className="profile-photo-editor"><span className="profile-photo-preview">{draft.photo ? <img src={draft.photo} alt="Student profile preview"/> : draft.initials}</span><span><strong>{draft.photo ? 'Profile photo selected' : 'Initials avatar'}</strong><small>{draft.photo ? 'This photo replaces your initials in the header.' : 'Your initials update automatically from your name.'}</small></span>{draft.photo ? <button onClick={() => setDraft({...draft,photo:null})}>Remove photo</button> : null}</div><label>Display name<input value={draft.name} onChange={(e) => changeName(e.target.value)}/></label><label>Initials (automatic)<input value={draft.initials} readOnly aria-readonly="true"/></label><label>Profile photo (optional)<input type="file" accept="image/*" onChange={choosePhoto}/><small className="field-help">Choose a photo or avatar image. It remains only in this prototype session.</small></label><label>Program<input value={draft.program} onChange={(e) => setDraft({...draft, program:e.target.value})}/></label></div><div className="modal-actions"><button className="primary" onClick={() => { setProfile({...draft,initials:initialsFromName(draft.name)}); notify('Student profile updated.'); onClose(); }}>Save profile</button></div></Modal>;
}

function LegacyPlacementSettings({ placements, setPlacements, onClose, notify }) {
  const [selected, setSelected] = useState(placements[0].id);
  const active = placements.find((p) => p.id === selected);
  const update = (fn) => setPlacements((all) => all.map((p) => p.id === selected ? fn(p) : p));
  const addPlacement = () => { const id = `placement-${Date.now()}`; setPlacements((all) => [...all, { id, name:'New Clinical Placement', target:90, completed:0, icon:'stethoscope', preceptors:[{ id:`preceptor-${Date.now()}`, name:'New Preceptor', primary:true, completed:0 }] }]); setSelected(id); notify('New Clinical Placement added.'); };
  return <Modal title="Clinical Placement management" onClose={onClose} wide><div className="settings-grid"><nav>{placements.map((p) => <button className={p.id === selected ? 'active' : ''} key={p.id} onClick={() => setSelected(p.id)}>{p.name}</button>)}<button onClick={addPlacement}><Plus /> Add placement</button></nav><div className="modal-form"><label>Placement name<input value={active.name} onChange={(e) => update((p) => ({...p,name:e.target.value}))}/></label><label>Target Hours<input type="number" min="1" value={active.target} onChange={(e) => update((p) => ({...p,target:Number(e.target.value)||1}))}/></label><h3>Preceptors</h3>{active.preceptors.map((person) => <div className="preceptor-editor" key={person.id}><input aria-label="Preceptor name" value={person.name} onChange={(e) => update((p) => ({...p,preceptors:p.preceptors.map((x) => x.id === person.id ? {...x,name:e.target.value}:x)}))}/><button className={person.primary ? 'primary' : ''} onClick={() => update((p) => ({...p,preceptors:p.preceptors.map((x) => ({...x,primary:x.id === person.id}))}))}>{person.primary ? 'Primary Preceptor' : 'Set Primary'}</button>{!person.primary ? <button className="icon-button danger-action" onClick={() => update((p) => ({...p,preceptors:p.preceptors.filter((x) => x.id !== person.id)}))}><Trash2 /></button> : null}</div>)}<button onClick={() => update((p) => ({...p,preceptors:[...p.preceptors,{id:`preceptor-${Date.now()}`,name:'New Preceptor',primary:false,completed:0}]}))}><Plus /> Add Preceptor</button><small>Changing the Primary Preceptor preserves documented hours and review history.</small></div></div></Modal>;
}

function AppMenu({ open, close }) { return <Modal title="Clinical Calendar" onClose={close}><div className="menu-list"><button onClick={() => open('placements')}><Stethoscope/> Clinical Placements</button><button onClick={() => open('profile')}><UserRound/> Student profile</button><button onClick={() => open('settings')}><Settings/> Settings</button><button onClick={() => open('notifications')}><Bell/> Notifications</button><button onClick={() => open('help')}><CircleHelp/> Help & how to use</button></div></Modal>; }
function HelpModal({ theme, onClose, onBack }) { const themeGuide = themeHelpGuides[theme] || { summary:'This theme has not supplied a visual-state guide yet. Workflow behavior remains unchanged.', states:[] }; return <Modal title="Help & how to use Clinical Calendar" onClose={onClose} onBack={onBack} wide><div className="theme-help-banner"><span>Current theme</span><strong>{theme}</strong><small>{themeGuide.summary}</small></div><div className="theme-state-guide" aria-label={`${theme} calendar color guide`}>{themeGuide.states.map(([state,description]) => <div key={state}><strong>{state}</strong><span>{description}</span></div>)}</div><div className="help-guide">
  <section><h3>Calendar states</h3><p>The active theme's guide above explains the appearance of Clinical Sessions, Work Shifts, Protected Days, and Today. Labels, event details, and accessible names remain present so calendar meaning never depends on color alone.</p></section>
  <section><h3>Selecting, scheduling, and moving dates</h3><p>Tap or click empty calendar days to build a batch. Tap a selected day again to remove it without changing any calendar entry underneath. Open an existing Work Shift or Clinical Session and change its Commitment date to move it without losing its hours, Placement, Preceptor, or history. Occupied and Protected dates cannot receive a moved entry.</p></section>
  <section><h3>Time and completion rules</h3><p>Hours are calculated automatically from start and end times, including overnight ranges. Future and current Clinical Sessions remain Scheduled. A Clinical Session entered after its date requires confirmation before its actual hours become Completed. Completed Hours may exceed both the scheduled duration and Target Hours.</p></section>
  <section><h3>Protected Days</h3><p>Each displayed week should contain one movable Protected Day. Planning incomplete opens the batch tray with Protected Day selected. Existing Protected Days can be moved or removed from their calendar details.</p></section>
  <section><h3>Placement and total progress</h3><p>The circular wheel shows Completed, Scheduled, and Unscheduled Hours for the selected Placement; tap it to move to the next Placement. Clinical Placement management opens on that same Placement, and selecting a different Placement there makes it the default wheel and scheduling choice without locking either control. The segmented Total Progress bar combines Completed Hours across every Placement. Over-target hours remain recorded rather than being discarded.</p></section>
  <section><h3>Preceptors</h3><p>Each Placement may have multiple Preceptors and exactly one Primary Preceptor. Clinical Sessions default to the selected Placement and its Primary Preceptor, but either can be changed for the batch. Progress remains placement-wide with a per-Preceptor breakdown.</p></section>
  <section><h3>Evaluation Plan</h3><p>Clinical Placement management controls Interim Review cadence plus Initial Self-Evaluation, Final Self-Evaluation, and Final Clinical Placement Review requirements. Interim reviews repeat at the configured Completed Hours interval and use the Primary Preceptor.</p></section>
  <section><h3>Attention and notifications</h3><p>Attention identifies past sessions awaiting confirmation, missing weekly Protected Days, and approaching evaluation work. Select a notification to open the action that resolves it. Temporary confirmation messages fly away automatically.</p></section>
  <section><h3>Settings, profile, and storage</h3><p>The mobile Settings tab and the three-line button both open the complete application menu. Settings controls week start, 12-hour or military time display, templates, theme, and synchronization mode. Student Profile is also available directly from the photo-or-initials button in both desktop and mobile headers. It derives initials automatically from the Display name and accepts an optional photo or avatar; removing the image restores the initials. Profile images and other demonstration changes remain only in this prototype session. Synced does not yet mean production cloud synchronization.</p></section>
</div></Modal>; }
function LegacySettingsModal({ onClose }) { return <Modal title="Settings" onClose={onClose}><div className="settings-list"><div><strong>Week starts</strong><span>Sunday</span></div><div><strong>Time display</strong><span>Military time</span></div><div><strong>Theme</strong><span>Borg Tactical Console</span></div><div><strong>Sync</strong><span className="success-copy">Google Drive-ready local prototype</span></div></div></Modal>; }

export default function App() {
  const [placements, setPlacements] = useState(clonePlacements);
  const [templates, setTemplates] = useState(() => defaultTemplates.map((item) => ({...item})));
  const [settings, setSettings] = useState({ weekStarts:'Sunday', timeDisplay:'Military time', theme:'Borg Tactical Console', syncMode:'Local prototype' });
  const [commitments, setCommitments] = useState(initialCommitments);
  const [protectedDates, setProtectedDates] = useState(() => new Set(['2026-08-08']));
  const [selectedDates, setSelectedDates] = useState(() => new Set(['2026-08-16','2026-08-18','2026-08-27','2026-08-28']));
  const [selectedPlacement, setSelectedPlacement] = useState('family');
  const [anchor, setAnchor] = useState(new Date(2026,7,1));
  const [view, setView] = useState('Month');
  const [expanded, setExpanded] = useState(true);
  const [trayRequest, setTrayRequest] = useState({ id:0, kind:'Clinical Session' });
  const [protectMode, setProtectMode] = useState(false);
  const [movingProtected, setMovingProtected] = useState(null);
  const [modal, setModal] = useState(null);
  const [evaluations, setEvaluations] = useState(initialEvaluations);
  const [profile, setProfile] = useState({ name:'Alex Bennett', initials:'AB', program:'Family Nurse Practitioner', photo:null });
  const [toast, setToast] = useState({ message:'', nonce:0 });
  const notify = (message) => setToast((t) => ({ message, nonce:t.nonce+1 }));
  const metrics = useMemo(() => derivePlacementMetrics(placements, commitments), [placements, commitments]);
  const activeCommitments = useMemo(() => commitments.filter(isActiveCommitment), [commitments]);
  const calendarCommitments = useMemo(() => commitments.filter(isCalendarCommitment), [commitments]);
  const conflicts = useMemo(() => [...selectedDates].filter((d) => calendarCommitments.some((c) => c.date === d) || protectedDates.has(d)), [selectedDates, calendarCommitments, protectedDates]);
  const awaiting = commitments.filter((c) => c.status === 'awaiting-confirmation');
  const pendingReviews = evaluations.filter((e) => e.current && e.status !== 'Documented');
  const displayedWeeks = useMemo(() => monthCells(anchor).reduce((rows, d, i) => { if (i % 7 === 0) rows.push([]); rows.at(-1).push(d.iso); return rows; }, []), [anchor]);
  const planningIncomplete = displayedWeeks.some((week) => !week.some((d) => protectedDates.has(d)));
  const notices = [
    ...(awaiting.length ? [{ id:'confirm', Icon:CalendarDays, tone:'danger', title:`${awaiting.length} session needs confirmation`, detail:'Confirm, cancel, correct, or mark it missed.', target:'commitment' }] : []),
    ...(planningIncomplete ? [{ id:'protect', Icon:Clock3, tone:'warning', title:'Planning incomplete', detail:'Choose a Protected Day for each displayed week.', target:'protect' }] : []),
    ...(pendingReviews.length ? [{ id:'review', Icon:FileClock, tone:'warning', title:'Interim Review approaching', detail:`${pendingReviews.length} required items are not documented.`, target:'evaluations' }] : []),
  ];
  const selectedMetric = metrics.find((p) => p.id === selectedPlacement) || metrics[0];
  const visibleEvaluations = evaluations.filter((evaluation) => {
    const requirement = evaluationRequirementById[evaluation.id];
    return !requirement || selectedMetric.evaluationPlan?.[requirement] !== false;
  });

  const onDay = (date) => {
    const commitment = calendarCommitments.find((c) => c.date === date);
    if (selectedDates.has(date)) {
      setSelectedDates((current) => { const next = new Set(current); next.delete(date); return next; });
      notify(`${prettyDate(date, true)} removed from the current batch. Existing calendar data was not changed.`);
      return;
    }
    if (protectMode) {
      if (commitment) return notify(`${prettyDate(date, true)} already has a commitment. Choose an empty day.`);
      setProtectedDates((current) => { const next = new Set(current); if (movingProtected) next.delete(movingProtected); next.add(date); return next; });
      notify(movingProtected ? `Protected Day moved to ${prettyDate(date, true)}.` : `${prettyDate(date, true)} is now blocked as a Protected Day.`);
      setMovingProtected(null); setProtectMode(false); return;
    }
    if (commitment) return setModal({ type:'commitment', id:commitment.id });
    if (protectedDates.has(date)) return setModal({ type:'protected', date });
    setSelectedDates((current) => { const next = new Set(current); next.has(date) ? next.delete(date) : next.add(date); return next; });
  };
  const startProtect = () => {
    if (selectedDates.size) {
      if (conflicts.length) return notify('Protected Day batch contains conflicts. Remove conflicting dates before applying it.');
      setProtectedDates((current) => new Set([...current,...selectedDates]));
      notify(`${selectedDates.size} selected dates are now Protected Days.`);
      setSelectedDates(new Set());
      return;
    }
    setProtectMode(true); notify('Protected Day mode: choose an empty date.');
  };
  const openTray = (kind = 'Clinical Session') => {
    setProtectMode(false);
    setTrayRequest((current) => ({ id:current.id + 1, kind }));
    setExpanded(true);
  };
  const apply = ({ dates, kind, placementId, preceptorId, start, end, hours }) => {
    if (kind === 'Protected Day') {
      setProtectedDates((current) => new Set([...current,...dates]));
      setSelectedDates(new Set());
      notify(`${dates.length} Protected Days added from the batch tray.`);
      return;
    }
    const placement = metrics.find((p) => p.id === placementId); const preceptor = placement?.preceptors.find((p) => p.id === preceptorId);
    const stamp = Date.now();
    const today = new Date().toISOString().slice(0,10);
    setCommitments((all) => [...all, ...dates.map((date, i) => ({ id:`added-${stamp}-${i}`, date, time:`${start}-${end}`, hours, type:kind === 'Clinical Session' ? 'clinical':'work', status:date < today && kind === 'Clinical Session' ? 'awaiting-confirmation':'scheduled', placementId:kind === 'Clinical Session' ? placementId:undefined, preceptorId:kind === 'Clinical Session' ? preceptorId:undefined, label:kind === 'Clinical Session' ? `${placement.name} - ${preceptor.name}`:'Work Shift' }))]);
    setSelectedDates(new Set()); if (kind === 'Clinical Session') setSelectedPlacement(placementId);
    const retrospective = dates.filter((date) => date < today).length;
    notify(`${dates.length} ${kind === 'Clinical Session' ? 'Clinical Sessions' : 'Work Shifts'} added. ${retrospective && kind === 'Clinical Session' ? `${retrospective} retrospective sessions await confirmation.`:'Future/current sessions are Scheduled.'}`);
  };
  const actOnCommitment = (action) => {
    const id = modal.id; const item = commitments.find((c) => c.id === id);
    setCommitments((all) => action === 'delete' ? all.filter((c) => c.id !== id) : all.map((c) => c.id === id ? {...c,status:action}:c));
    setModal(modal.backTo?.type === 'notifications' ? modal.backTo : null); notify(action === 'completed' ? 'Session confirmed: 12 hours moved from Scheduled to Completed.' : action === 'delete' ? 'Commitment deleted and all projections recalculated.' : `Session marked ${action}; Scheduled Hours were recalculated.`);
    if (item?.placementId) setSelectedPlacement(item.placementId);
  };
  const saveCommitment = (changes) => {
    const id = modal.id;
    const item = commitments.find((commitment) => commitment.id === id);
    if (!item) return;
    const nextDate = changes.date || item.date;
    const occupied = commitments.some((commitment) => commitment.id !== id && isActiveCommitment(commitment) && commitment.date === nextDate);
    if (protectedDates.has(nextDate) || occupied) {
      notify(`${prettyDate(nextDate, true)} already contains a commitment or Protected Day. Nothing was moved.`);
      return;
    }
    const today = new Date().toISOString().slice(0,10);
    let nextStatus = changes.status;
    if (item.type === 'clinical' && nextDate >= today && nextStatus === 'completed') nextStatus = 'scheduled';
    if (item.type === 'clinical' && nextDate < today && nextStatus === 'scheduled') nextStatus = 'awaiting-confirmation';
    setCommitments((all) => all.map((commitment) => commitment.id === id ? {...commitment,...changes,date:nextDate,status:nextStatus}:commitment));
    setSelectedDates((current) => { const next = new Set(current); next.delete(nextDate); return next; });
    setModal(modal.backTo?.type === 'notifications' ? modal.backTo : null);
    const moveMessage = nextDate !== item.date ? `Moved to ${prettyDate(nextDate, true)}. ` : '';
    notify(`${moveMessage}${changes.hours} actual hours saved as ${nextStatus}. Placement, Preceptor, and history were preserved.`);
  };
  const openNotice = (notice) => {
    const backTo = { ...modal };
    if (notice.target === 'commitment') setModal({type:'commitment',id:awaiting[0].id,backTo});
    else if (notice.target === 'evaluations') setModal({type:'evaluations',backTo});
    else { setModal(null); openTray('Protected Day'); }
  };
  const open = (type, fromMenu = false) => setModal({ type, backTo:fromMenu ? {type:'menu'} : null });
  const backFromModal = modal?.backTo ? () => setModal(modal.backTo) : undefined;
  const documentEvaluation = (id) => {
    setEvaluations((all) => all.map((evaluation) => evaluation.id === id ? {...evaluation,status:'Documented',detail:'Medatrax · today'} : evaluation));
    notify('Evaluation marked documented in Medatrax.');
  };
  const cyclePlacement = () => setSelectedPlacement((current) => metrics[(Math.max(0,metrics.findIndex((item) => item.id === current)) + 1) % metrics.length].id);
  const commitment = modal?.type === 'commitment' ? commitments.find((c) => c.id === modal.id) : null;

  return <>
    <main className="desktop-app app-frame">
      <Header count={notices.length} open={open} onAdd={() => openTray()} profile={profile} />
      <PlacementDock placements={metrics} selected={selectedPlacement} onSelect={setSelectedPlacement} onSettings={() => open('placements')} />
      <section className="calendar-workspace"><div className="calendar-toolbar"><div><button className="icon-button" onClick={() => setAnchor(movePeriod(anchor, view, -1))}><ChevronLeft/></button><button className="icon-button" onClick={() => setAnchor(movePeriod(anchor, view, 1))}><ChevronRight/></button><h1>{periodTitle(anchor, view)}</h1></div><div className="view-switch">{['Month','Week','Agenda'].map((x) => <button className={view === x ? 'active':''} key={x} onClick={() => setView(x)}>{x}</button>)}</div><div className="toolbar-actions"><button className={`protect-button ${protectMode ? 'active':''}`} onClick={startProtect}><Clock3/> {protectMode ? 'Select a day':'Protect day'}</button><button className="add-button" onClick={() => openTray()}><Plus/> Add schedule</button></div></div>
        {view === 'Month' ? <CalendarGrid anchor={anchor} commitments={commitments} protectedDates={protectedDates} selectedDates={selectedDates} onDay={onDay} timeDisplay={settings.timeDisplay}/> : view === 'Week' ? <WeekView anchor={anchor} commitments={commitments} protectedDates={protectedDates} onDay={onDay} timeDisplay={settings.timeDisplay}/> : <AgendaView anchor={anchor} commitments={commitments} protectedDates={protectedDates} onDay={onDay} timeDisplay={settings.timeDisplay}/>} 
        <PlanningTray key={`${trayRequest.id}|${settings.timeDisplay}|${templates.map((item) => `${item.id}:${item.name}:${item.start}:${item.end}:${item.hours}`).join('|')}`} initialKind={trayRequest.kind} placements={metrics} selectedPlacement={selectedPlacement} selectedDates={selectedDates} conflicts={conflicts} expanded={expanded} setExpanded={setExpanded} onRemoveConflicts={() => { setSelectedDates((s) => new Set([...s].filter((d) => !conflicts.includes(d)))); notify('Conflicting dates removed from this batch.'); }} onApply={apply} templates={templates} timeDisplay={settings.timeDisplay}/>
      </section>
      <aside className="insight-rail"><ProgressDonut placement={selectedMetric} onNext={cyclePlacement}/>{modal?.type === 'evaluations' ? <Evaluations evaluations={visibleEvaluations} cadence={selectedMetric.reviewCadence} onDocument={documentEvaluation} onClose={() => setModal(null)}/> : <InterimCard pending={pendingReviews.length} onView={() => open('evaluations')}/>}<Attention awaiting={awaiting.length} planningIncomplete={planningIncomplete} onConfirm={() => setModal({type:'commitment',id:awaiting[0]?.id})} onPlan={() => openTray('Protected Day')}/><section className="synced-panel tactical-panel"><span className="round-icon success"><Check/></span><span><strong>Synced</strong><small>Local prototype state</small></span><i className="status-pip"/></section></aside>
    </main>
    <main className="mobile-app app-frame"><Header count={notices.length} open={open} onAdd={() => openTray()} profile={profile}/><div className="mobile-month-title"><button onClick={() => setAnchor(movePeriod(anchor, 'Month', -1))}><ChevronLeft/></button><h1>{periodTitle(anchor,'Month')}</h1><button onClick={() => setAnchor(movePeriod(anchor, 'Month', 1))}><ChevronRight/></button></div><CalendarGrid compact anchor={anchor} commitments={commitments} protectedDates={protectedDates} selectedDates={selectedDates} onDay={onDay} timeDisplay={settings.timeDisplay}/><ProgressDonut placement={selectedMetric} onNext={cyclePlacement} touch/><TotalProgress placements={metrics} className="mobile-total-progress tactical-panel"/><PlanningTray key={`mobile|${trayRequest.id}|${settings.timeDisplay}|${templates.map((item) => `${item.id}:${item.name}:${item.start}:${item.end}:${item.hours}`).join('|')}`} initialKind={trayRequest.kind} placements={metrics} selectedPlacement={selectedPlacement} selectedDates={selectedDates} conflicts={conflicts} expanded={expanded} setExpanded={setExpanded} onRemoveConflicts={() => setSelectedDates((s) => new Set([...s].filter((d) => !conflicts.includes(d))))} onApply={apply} templates={templates} timeDisplay={settings.timeDisplay}/><nav className="bottom-nav"><button className="active"><CalendarDays/><span>Calendar</span></button><button onClick={() => open('placements')}><UsersRound/><span>Placements</span></button><button onClick={() => open('notifications')}><Bell/>{notices.length ? <b>{notices.length}</b>:null}<span>Attention</span></button><button onClick={() => open('menu')}><Settings/><span>Settings</span></button></nav></main>
    {commitment ? <CommitmentModal commitment={commitment} placements={metrics} onAction={actOnCommitment} onSave={saveCommitment} timeDisplay={settings.timeDisplay} onClose={() => setModal(null)} onBack={backFromModal}/> : null}
    {modal?.type === 'protected' ? <ProtectedModal date={modal.date} onClose={() => setModal(null)} onRemove={() => { setProtectedDates((s) => {const n=new Set(s);n.delete(modal.date);return n;});setModal(null);notify('Protected Day removed. Planning status was recalculated.'); }} onMove={() => {setMovingProtected(modal.date);setProtectMode(true);setModal(null);notify('Choose an empty date for the moved Protected Day.');}}/>:null}
    {modal?.type === 'notifications' ? <NotificationModal notices={notices} onOpen={openNotice} onClose={() => setModal(null)} onBack={backFromModal}/>:null}
    {modal?.type === 'profile' ? <ProfileModal profile={profile} setProfile={setProfile} onClose={() => setModal(null)} onBack={backFromModal} notify={notify}/>:null}
    {modal?.type === 'placements' ? <PlacementSettings placements={placements} setPlacements={setPlacements} selectedPlacement={selectedPlacement} onSelectPlacement={setSelectedPlacement} onClose={() => setModal(null)} onBack={backFromModal} notify={notify}/>:null}
    {modal?.type === 'menu' ? <AppMenu open={(type) => open(type,true)} close={() => setModal(null)}/>:null}
    {modal?.type === 'settings' ? <SettingsModal settings={settings} setSettings={setSettings} templates={templates} setTemplates={setTemplates} onClose={() => setModal(null)} onBack={backFromModal} notify={notify}/>:null}
    {modal?.type === 'help' ? <HelpModal theme={settings.theme} onClose={() => setModal(null)} onBack={backFromModal}/>:null}
    {modal?.type === 'evaluations' ? <div className="mobile-evaluation-modal"><EvaluationModal evaluations={visibleEvaluations} cadence={selectedMetric.reviewCadence} onDocument={documentEvaluation} onClose={() => setModal(null)} onBack={backFromModal}/></div> : null}
    <Toast message={toast.message} nonce={toast.nonce}/>{import.meta.env.DEV ? <div className="prototype-marker">Prototype · Variant F</div>:null}
  </>;
}
