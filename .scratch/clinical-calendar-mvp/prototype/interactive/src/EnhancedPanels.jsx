import { useEffect, useState } from 'react';
import { Check, ChevronDown, CircleAlert, Plus, Trash2, X } from 'lucide-react';

export const defaultTemplates = [
  { id:'day', name:'Day Shift', start:'07:00', end:'19:00', hours:12 },
  { id:'evening', name:'Evening Shift', start:'11:00', end:'23:00', hours:12 },
];

const calculateHours = (start, end) => {
  const [startHour, startMinute] = start.split(':').map(Number);
  const [endHour, endMinute] = end.split(':').map(Number);
  if (![startHour,startMinute,endHour,endMinute].every(Number.isFinite)) return 0;
  let minutes = (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
  if (minutes <= 0) minutes += 24 * 60;
  return Math.round((minutes / 60) * 100) / 100;
};

const normalizeTimeInput = (raw, preference, selectedMeridiem = 'AM') => {
  const cleaned = String(raw).trim().toUpperCase();
  const explicitMeridiem = cleaned.match(/\b(AM|PM)\b/)?.[1];
  const numeric = cleaned.replace(/\b(AM|PM)\b/g, '').trim();
  let hour;
  let minute;
  if (numeric.includes(':')) {
    const parts = numeric.split(':');
    if (parts.length !== 2) return null;
    hour = Number(parts[0]);
    minute = Number(parts[1]);
  } else if (/^\d{1,4}$/.test(numeric)) {
    hour = Number(numeric.length <= 2 ? numeric : numeric.slice(0, -2));
    minute = Number(numeric.length <= 2 ? 0 : numeric.slice(-2));
  } else return null;
  if (!Number.isInteger(hour) || !Number.isInteger(minute) || minute < 0 || minute > 59) return null;
  const meridiem = explicitMeridiem || (preference === '12-hour time' && hour <= 12 ? selectedMeridiem : null);
  if (meridiem) {
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (meridiem === 'PM' ? 12 : 0);
  }
  if (hour < 0 || hour > 23) return null;
  return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
};

const displayTime = (value, preference) => {
  if (preference === 'Military time') return value;
  const [hour, minute] = value.split(':').map(Number);
  return `${hour % 12 || 12}:${String(minute).padStart(2,'0')} ${hour >= 12 ? 'PM' : 'AM'}`;
};

const displayRange = (start, end, preference) => `${displayTime(start,preference)}-${displayTime(end,preference)}`;

const inputTime = (value, preference) => preference === '12-hour time'
  ? displayTime(value, preference).replace(/\s(?:AM|PM)$/, '')
  : value;

function FlexibleTimeField({ label, value, onChange, preference }) {
  const [draft, setDraft] = useState(() => inputTime(value, preference));
  const meridiem = Number(value.split(':')[0]) >= 12 ? 'PM' : 'AM';
  useEffect(() => setDraft(inputTime(value, preference)), [value, preference]);
  const commit = (nextMeridiem = meridiem) => {
    const normalized = normalizeTimeInput(draft, preference, nextMeridiem);
    if (!normalized) return setDraft(inputTime(value, preference));
    onChange(normalized);
    setDraft(inputTime(normalized, preference));
  };
  return <label>{label}<div className="time-entry"><input aria-label={label} value={draft} onChange={(event) => setDraft(event.target.value)} onBlur={() => commit()} onKeyDown={(event) => event.key === 'Enter' && event.currentTarget.blur()} inputMode="numeric" placeholder={preference === '12-hour time' ? 'h:mm or 1400' : 'HHMM or HH:MM'}/>{preference === '12-hour time' ? <select aria-label={`${label} AM or PM`} value={meridiem} onChange={(event) => commit(event.target.value)}><option>AM</option><option>PM</option></select> : null}</div></label>;
}

const prettyDate = (iso) => new Date(`${iso}T12:00:00`).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });

function PanelModal({ title, onClose, onBack, children, wide = false }) {
  return <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}><section className={`modal tactical-panel ${wide ? 'wide' : ''}`} role="dialog" aria-modal="true" aria-label={title}><header>{onBack ? <button className="modal-back" onClick={onBack}>Back</button>:null}<h2>{title}</h2><button className="icon-button" onClick={onClose} aria-label="Close"><X /></button></header>{children}</section></div>;
}

function LegacyPlanningTray({ placements, selectedPlacement, selectedDates, conflicts, expanded, setExpanded, onRemoveConflicts, onApply, templates = defaultTemplates }) {
  const [stage, setStage] = useState(0);
  const [kind, setKind] = useState('Clinical Session');
  const [templateId, setTemplateId] = useState(templates[0].id);
  const initialTemplate = templates.find((item) => item.id === templateId) || templates[0];
  const [start, setStart] = useState(initialTemplate.start);
  const [end, setEnd] = useState(initialTemplate.end);
  const [hours, setHours] = useState(initialTemplate.hours);
  const [recordAs, setRecordAs] = useState('Scheduled');
  const [placementId, setPlacementId] = useState(selectedPlacement);
  const placement = placements.find((item) => item.id === placementId) || placements[0];
  const primary = placement.preceptors.find((person) => person.primary) || placement.preceptors[0];
  const [preceptorId, setPreceptorId] = useState(primary?.id || '');
  const countedHours = Math.max(0, Number(hours) || 0);

  const changeTemplate = (id) => {
    const next = templates.find((item) => item.id === id) || templates[0];
    setTemplateId(next.id); setStart(next.start); setEnd(next.end); setHours(next.hours);
  };
  const changePlacement = (id) => {
    const next = placements.find((item) => item.id === id);
    setPlacementId(id);
    setPreceptorId((next.preceptors.find((person) => person.primary) || next.preceptors[0])?.id || '');
  };
  const apply = () => {
    onApply({ dates:[...selectedDates], kind, placementId, preceptorId, start, end, hours:countedHours, recordAs });
    setStage(0); setExpanded(false);
  };

  return <section className={`planning-tray tactical-panel ${expanded ? 'expanded' : 'collapsed'}`}>
    <div className="tray-summary"><span><strong>{selectedDates.size} dates selected</strong><i />{kind}<i />{countedHours} hr each<i className={conflicts.length ? 'danger-dot' : ''}/>{conflicts.length ? `${conflicts.length} conflict` : recordAs}</span><div><button className="icon-button" onClick={() => setExpanded(!expanded)} aria-label={expanded ? 'Collapse planning tray' : 'Expand planning tray'}><ChevronDown className={expanded ? '' : 'rotate'}/></button><button onClick={() => setExpanded(true)}>Expand</button><button className="primary" onClick={() => { setExpanded(true); setStage(2); }}>Review</button></div></div>
    {expanded ? <div className="tray-body"><div className="stage-tabs">{['Time & hours','Placement','Review'].map((name,index) => <button className={stage === index ? 'active' : ''} key={name} onClick={() => setStage(index)}><span>{index+1}</span><b>{name}</b><small>{index === 0 ? 'Template or exact hours' : index === 1 ? 'Placement, Preceptor, and status' : 'Resolve conflicts and apply'}</small></button>)}</div>
      <div className="stage-content">
        {stage === 0 ? <div className="form-stage schedule-fields"><label>Commitment<select value={kind} onChange={(event) => setKind(event.target.value)}><option>Clinical Session</option><option>Work Shift</option></select></label><label>Template<select value={templateId} onChange={(event) => changeTemplate(event.target.value)}>{templates.map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>Start time<input type="text" inputMode="numeric" pattern="[0-2][0-9]:[0-5][0-9]" placeholder="HH:MM" value={start} onChange={(event) => setStart(event.target.value)}/></label><label>End time<input type="text" inputMode="numeric" pattern="[0-2][0-9]:[0-5][0-9]" placeholder="HH:MM" value={end} onChange={(event) => setEnd(event.target.value)}/></label><label>Counted hours<input type="number" min="0.25" step="0.25" value={hours} onChange={(event) => setHours(event.target.value)}/></label><div className="date-chips">{[...selectedDates].map((date) => <span key={date}>{prettyDate(date)}</span>)}</div></div> : null}
        {stage === 1 ? <div className="form-stage schedule-fields">{kind === 'Clinical Session' ? <><label>Placement<select value={placementId} onChange={(event) => changePlacement(event.target.value)}>{placements.map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>Preceptor<select value={preceptorId} onChange={(event) => setPreceptorId(event.target.value)}>{placement.preceptors.map((person) => <option value={person.id} key={person.id}>{person.name}{person.primary ? ' - Primary' : ''}</option>)}</select></label></> : null}<label>Record as<select value={recordAs} onChange={(event) => setRecordAs(event.target.value)}><option>Scheduled</option><option>Completed</option></select></label><div className="impact"><span>Applies to</span><strong>{selectedDates.size} dates · {start}-{end} · {countedHours} hours each</strong><small>{kind === 'Clinical Session' ? `${selectedDates.size * countedHours} ${recordAs} Hours will be recorded. Completed Hours are never capped at Target Hours.` : 'Work Shifts do not change Clinical Placement hours.'}</small></div></div> : null}
        {stage === 2 ? <div className={`conflict-review ${conflicts.length ? '' : 'resolved'}`}>{conflicts.length ? <CircleAlert/> : <Check/>}<span><strong>{conflicts.length ? 'Batch cannot be applied' : 'Batch is valid'}</strong><small>{conflicts.length ? `${conflicts.map(prettyDate).join(', ')} already contain a commitment or Protected Day.` : `${selectedDates.size} commitments · ${selectedDates.size * countedHours} total hours · ${recordAs}.`}</small></span>{conflicts.length ? <button onClick={onRemoveConflicts}>Remove conflicting dates</button> : <b>Ready</b>}</div> : null}
      </div><div className="tray-actions"><button onClick={() => setStage(Math.max(0,stage-1))} disabled={!stage}>Back</button><button className="primary" onClick={stage === 2 ? apply : () => setStage(stage+1)} disabled={stage === 2 && (!selectedDates.size || conflicts.length || countedHours <= 0)}>{stage === 2 ? 'Apply schedule' : 'Next'}</button></div>
    </div> : null}
  </section>;
}

function CurrentPlanningTray({ placements, selectedPlacement, selectedDates, conflicts, expanded, setExpanded, onRemoveConflicts, onApply, templates = defaultTemplates, timeDisplay = 'Military time' }) {
  const [stage,setStage]=useState(0);
  const [kind,setKind]=useState('Clinical Session');
  const [templateId,setTemplateId]=useState(templates[0].id);
  const chosen=templates.find((item)=>item.id===templateId)||templates[0];
  const [start,setStart]=useState(chosen.start);
  const [end,setEnd]=useState(chosen.end);
  const [placementId,setPlacementId]=useState(selectedPlacement);
  const placement=placements.find((item)=>item.id===placementId)||placements[0];
  const [preceptorId,setPreceptorId]=useState((placement.preceptors.find((person)=>person.primary)||placement.preceptors[0])?.id||'');
  const hours=calculateHours(start,end);
  const chooseTemplate=(id)=>{const next=templates.find((item)=>item.id===id)||templates[0];setTemplateId(next.id);setStart(next.start);setEnd(next.end);};
  const choosePlacement=(id)=>{const next=placements.find((item)=>item.id===id);setPlacementId(id);setPreceptorId((next.preceptors.find((person)=>person.primary)||next.preceptors[0])?.id||'');};
  const apply=()=>{onApply({dates:[...selectedDates],kind,placementId,preceptorId,start,end,hours});setStage(0);setExpanded(false);};
  return <section className={`planning-tray tactical-panel ${expanded?'expanded':'collapsed'}`}>
    <div className="tray-summary"><span><strong>{selectedDates.size} dates selected</strong><i/>{kind}<i/>{kind==='Protected Day'?'All day':`${hours} hr each`}<i className={conflicts.length?'danger-dot':''}/>{conflicts.length?`${conflicts.length} conflict`:'Ready'}</span><div><button className="icon-button" onClick={()=>setExpanded(!expanded)} aria-label={expanded?'Collapse planning tray':'Expand planning tray'}><ChevronDown className={expanded?'':'rotate'}/></button><button onClick={()=>setExpanded(true)}>Expand</button><button className="primary" onClick={()=>{setExpanded(true);setStage(2);}}>Review</button></div></div>
    {expanded?<div className="tray-body"><div className="stage-tabs">{['Time & hours','Placement','Review'].map((name,index)=><button className={stage===index?'active':''} key={name} onClick={()=>setStage(index)}><span>{index+1}</span><b>{name}</b><small>{index===0?'Choose type and times':index===1?'Choose placement and Preceptor':'Resolve conflicts and apply'}</small></button>)}</div><div className="stage-content">
      {stage===0?<div className="form-stage schedule-fields"><label>Commitment<select value={kind} onChange={(event)=>setKind(event.target.value)}><option>Clinical Session</option><option>Work Shift</option><option>Protected Day</option></select></label>{kind!=='Protected Day'?<><label>Template<select value={templateId} onChange={(event)=>chooseTemplate(event.target.value)}>{templates.map((item)=><option value={item.id} key={item.id}>{item.name} — {displayRange(item.start,item.end,timeDisplay)} ({calculateHours(item.start,item.end)} hr)</option>)}</select><small className="field-help">Choosing a template fills the times below; changing the times modifies only this batch.</small></label><label>Start (HH:MM)<input value={start} onChange={(event)=>setStart(event.target.value)} inputMode="numeric"/></label><label>End (HH:MM)<input value={end} onChange={(event)=>setEnd(event.target.value)} inputMode="numeric"/></label><div className="calculated-hours"><span>Automatically calculated</span><strong>{displayRange(start,end,timeDisplay)} · {hours} hours</strong></div></>:null}<div className="date-chips">{[...selectedDates].map((date)=><span key={date}>{prettyDate(date)}</span>)}</div></div>:null}
      {stage===1?<div className="form-stage schedule-fields">{kind==='Clinical Session'?<><label>Placement<select value={placementId} onChange={(event)=>choosePlacement(event.target.value)}>{placements.map((item)=><option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>Preceptor<select value={preceptorId} onChange={(event)=>setPreceptorId(event.target.value)}>{placement.preceptors.map((person)=><option value={person.id} key={person.id}>{person.name}{person.primary?' - Primary':''}</option>)}</select></label></>:null}<div className="impact"><strong>Status is date-driven</strong><small>Future and current dates are Scheduled. Past dates require confirmation before becoming Completed.</small></div></div>:null}
      {stage===2?<div className={`conflict-review ${conflicts.length?'':'resolved'}`}>{conflicts.length?<CircleAlert/>:<Check/>}<span><strong>{conflicts.length?'Batch cannot be applied':'Batch is valid'}</strong><small>{conflicts.length?`${conflicts.map(prettyDate).join(', ')} already contain a commitment or Protected Day.`:`${selectedDates.size} ${kind==='Protected Day'?'Protected Days':`${hours}-hour commitments`} will be added.`}</small></span>{conflicts.length?<button onClick={onRemoveConflicts}>Remove conflicting dates</button>:<b>Ready</b>}</div>:null}
    </div><div className="tray-actions"><button onClick={()=>setStage(Math.max(0,stage-1))} disabled={!stage}>Back</button><button className="primary" onClick={stage===2?apply:()=>setStage(stage+1)} disabled={stage===2&&(!selectedDates.size||conflicts.length||(kind!=='Protected Day'&&hours<=0))}>{stage===2?'Apply batch':'Next'}</button></div></div>:null}
  </section>;
}

export function PlanningTray({ placements, selectedPlacement, selectedDates, conflicts, expanded, setExpanded, onRemoveConflicts, onApply, templates = defaultTemplates, timeDisplay = 'Military time', initialKind = 'Clinical Session' }) {
  const [stage, setStage] = useState(0);
  const [kind, setKind] = useState(initialKind);
  const [templateId, setTemplateId] = useState(templates[0].id);
  const chosen = templates.find((item) => item.id === templateId) || templates[0];
  const [start, setStart] = useState(chosen.start);
  const [end, setEnd] = useState(chosen.end);
  const [placementId, setPlacementId] = useState(selectedPlacement);
  const placement = placements.find((item) => item.id === placementId) || placements[0];
  const [preceptorId, setPreceptorId] = useState((placement.preceptors.find((person) => person.primary) || placement.preceptors[0])?.id || '');
  const hours = calculateHours(start, end);
  useEffect(() => {
    const next = placements.find((item) => item.id === selectedPlacement);
    if (!next) return;
    setPlacementId(next.id);
    setPreceptorId((next.preceptors.find((person) => person.primary) || next.preceptors[0])?.id || '');
  }, [selectedPlacement]);
  const chooseTemplate = (id) => {
    const next = templates.find((item) => item.id === id) || templates[0];
    setTemplateId(next.id); setStart(next.start); setEnd(next.end);
  };
  const chooseKind = (value) => {
    setKind(value);
    if (value !== 'Protected Day') { setStart(chosen.start); setEnd(chosen.end); }
  };
  const choosePlacement = (id) => {
    const next = placements.find((item) => item.id === id);
    setPlacementId(id);
    setPreceptorId((next.preceptors.find((person) => person.primary) || next.preceptors[0])?.id || '');
  };
  const apply = () => {
    onApply({ dates:[...selectedDates], kind, placementId, preceptorId, start, end, hours });
    setStage(0); setExpanded(false);
  };
  return <section className={`planning-tray tactical-panel ${expanded ? 'expanded' : 'collapsed'}`}>
    <div className="tray-summary"><span><strong>{selectedDates.size} dates selected</strong><i/>{kind}<i/>{kind === 'Protected Day' ? 'All day' : `${hours} hr each`}<i className={conflicts.length ? 'danger-dot' : ''}/>{conflicts.length ? `${conflicts.length} conflict` : 'Ready'}</span><div><button className="icon-button" onClick={() => setExpanded(!expanded)} aria-label={expanded ? 'Collapse planning tray' : 'Expand planning tray'}><ChevronDown className={expanded ? '' : 'rotate'}/></button><button className="primary" onClick={() => { setExpanded(true); setStage(2); }}>Review</button></div></div>
    {expanded ? <div className="tray-body"><div className="stage-tabs">{['Time & hours','Placement','Review'].map((name,index) => <button className={stage === index ? 'active' : ''} key={name} onClick={() => setStage(index)}><span>{index + 1}</span><b>{name}</b><small>{index === 0 ? 'Choose type and times' : index === 1 ? 'Choose placement and Preceptor' : 'Resolve conflicts and apply'}</small></button>)}</div><div className="stage-content">
      {stage === 0 ? <div className="form-stage schedule-fields"><div className="schedule-choice-row"><label>Commitment<select value={kind} onChange={(event) => chooseKind(event.target.value)}><option>Clinical Session</option><option>Work Shift</option><option>Protected Day</option></select></label>{kind !== 'Protected Day' ? <label>Template<select value={templateId} onChange={(event) => chooseTemplate(event.target.value)}>{templates.map((item) => <option value={item.id} key={item.id}>{item.name} — {displayRange(item.start,item.end,timeDisplay)} ({calculateHours(item.start,item.end)} hr)</option>)}</select><small className="field-help">Choosing a template fills the times below; changing the times modifies only this batch.</small></label> : null}</div>{kind !== 'Protected Day' ? <div className="schedule-time-row"><FlexibleTimeField label="Start time" value={start} onChange={setStart} preference={timeDisplay}/><FlexibleTimeField label="End time" value={end} onChange={setEnd} preference={timeDisplay}/><div className="calculated-hours"><span>Automatically calculated</span><strong>{displayRange(start,end,timeDisplay)} · {hours} hours</strong></div></div> : null}<div className="date-chips">{[...selectedDates].map((date) => <span key={date}>{prettyDate(date)}</span>)}</div></div> : null}
      {stage === 1 ? <div className="form-stage schedule-fields">{kind === 'Clinical Session' ? <><label>Placement<select value={placementId} onChange={(event) => choosePlacement(event.target.value)}>{placements.map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>Preceptor<select value={preceptorId} onChange={(event) => setPreceptorId(event.target.value)}>{placement.preceptors.map((person) => <option value={person.id} key={person.id}>{person.name}{person.primary ? ' - Primary' : ''}</option>)}</select></label></> : null}<div className="impact"><strong>Status is date-driven</strong><small>Future and current dates are Scheduled. Past dates require confirmation before becoming Completed.</small></div></div> : null}
      {stage === 2 ? <div className={`conflict-review ${conflicts.length ? '' : 'resolved'}`}>{conflicts.length ? <CircleAlert/> : <Check/>}<span><strong>{conflicts.length ? 'Batch cannot be applied' : 'Batch is valid'}</strong><small>{conflicts.length ? `${conflicts.map(prettyDate).join(', ')} already contain a commitment or Protected Day.` : `${selectedDates.size} ${kind === 'Protected Day' ? 'Protected Days' : `${hours}-hour commitments`} will be added.`}</small></span>{conflicts.length ? <button onClick={onRemoveConflicts}>Remove conflicting dates</button> : <b>Ready</b>}</div> : null}
    </div><div className="tray-actions"><button onClick={() => setStage(Math.max(0,stage - 1))} disabled={!stage}>Back</button><button className="primary" onClick={stage === 2 ? apply : () => setStage(stage + 1)} disabled={stage === 2 && (!selectedDates.size || conflicts.length || (kind !== 'Protected Day' && hours <= 0))}>{stage === 2 ? 'Apply batch' : 'Next'}</button></div></div> : null}
  </section>;
}

function LegacyCommitmentModal({ commitment, placements, onSave, onAction, onClose }) {
  const placement = placements.find((item) => item.id === commitment.placementId);
  const preceptor = placement?.preceptors.find((person) => person.id === commitment.preceptorId);
  const [hours, setHours] = useState(commitment.hours);
  const [start, end] = commitment.time.split('-');
  const [actualStart, setActualStart] = useState(start);
  const [actualEnd, setActualEnd] = useState(end);
  const [status, setStatus] = useState(commitment.status === 'completed' ? 'Completed' : 'Scheduled');
  return <PanelModal title={commitment.type === 'clinical' ? 'Clinical Session' : 'Work Shift'} onClose={onClose}><div className="modal-form"><strong>{prettyDate(commitment.date)}</strong><label>Actual start<input type="time" value={actualStart} onChange={(event) => setActualStart(event.target.value)}/></label><label>Actual end<input type="time" value={actualEnd} onChange={(event) => setActualEnd(event.target.value)}/></label><label>Counted hours<input type="number" min="0.25" step="0.25" value={hours} onChange={(event) => setHours(event.target.value)}/></label>{commitment.type === 'clinical' ? <label>Record as<select value={status} onChange={(event) => setStatus(event.target.value)}><option>Scheduled</option><option>Completed</option></select></label> : null}{placement ? <div className="field-note">{placement.name} · {preceptor?.name}<br/>Completed Hours may exceed the planned duration or Target Hours; excess is retained as Over-Target Hours.</div> : null}</div><div className="modal-actions"><button className="primary" onClick={() => onSave({ hours:Number(hours), time:`${actualStart}-${actualEnd}`, status:status.toLowerCase() })}>Save actual hours</button>{commitment.type === 'clinical' && (commitment.status === 'scheduled' || commitment.status === 'awaiting-confirmation') ? <><button onClick={() => onAction('cancelled')}>Cancel session</button><button onClick={() => onAction('missed')}>Mark missed</button></> : null}<button className="danger-action" onClick={() => onAction('delete')}><Trash2/> Delete erroneous entry</button></div></PanelModal>;
}

function LegacyCommitmentEditor({ commitment, placements, onSave, onAction, onClose }) {
  const placement = placements.find((item) => item.id === commitment.placementId);
  const preceptor = placement?.preceptors.find((person) => person.id === commitment.preceptorId);
  const [startValue, endValue] = commitment.time.split('-');
  const [actualStart, setActualStart] = useState(startValue);
  const [actualEnd, setActualEnd] = useState(endValue);
  const [hours, setHours] = useState(commitment.hours);
  const [status, setStatus] = useState(commitment.status === 'completed' ? 'Completed' : 'Scheduled');
  return <PanelModal title={commitment.type === 'clinical' ? 'Clinical Session' : 'Work Shift'} onClose={onClose}>
    <div className="modal-form"><strong>{prettyDate(commitment.date)}</strong><label>Actual start (HH:MM)<input type="text" inputMode="numeric" pattern="[0-2][0-9]:[0-5][0-9]" placeholder="HH:MM" value={actualStart} onChange={(event) => setActualStart(event.target.value)}/></label><label>Actual end (HH:MM)<input type="text" inputMode="numeric" pattern="[0-2][0-9]:[0-5][0-9]" placeholder="HH:MM" value={actualEnd} onChange={(event) => setActualEnd(event.target.value)}/></label><label>Counted hours<input type="number" min="0.25" step="0.25" value={hours} onChange={(event) => setHours(event.target.value)}/></label>{commitment.type === 'clinical' ? <label>Record as<select value={status} onChange={(event) => setStatus(event.target.value)}><option>Scheduled</option><option>Completed</option></select></label>:null}{placement ? <div className="field-note">{placement.name} / {preceptor?.name}<br/>Completed Hours may exceed the planned duration or Target Hours; excess is retained as Over-Target Hours.</div>:null}</div>
    <div className="modal-actions"><button className="primary" onClick={() => onSave({hours:Number(hours),time:`${actualStart}-${actualEnd}`,status:status.toLowerCase()})}>Save actual hours</button>{commitment.type === 'clinical' && (commitment.status === 'scheduled' || commitment.status === 'awaiting-confirmation') ? <><button onClick={() => onAction('cancelled')}>Cancel session</button><button onClick={() => onAction('missed')}>Mark missed</button></>:null}<button className="danger-action" onClick={() => onAction('delete')}><Trash2/> Delete erroneous entry</button></div>
  </PanelModal>;
}

function CurrentCommitmentModal({ commitment, placements, onSave, onAction, onClose, timeDisplay = 'Military time' }) {
  const placement=placements.find((item)=>item.id===commitment.placementId);
  const preceptor=placement?.preceptors.find((person)=>person.id===commitment.preceptorId);
  const [startValue,endValue]=commitment.time.split('-');
  const [start,setStart]=useState(startValue);
  const [end,setEnd]=useState(endValue);
  const hours=calculateHours(start,end);
  const save=(status)=>onSave({hours,time:`${start}-${end}`,status});
  return <PanelModal title={commitment.type==='clinical'?'Clinical Session':'Work Shift'} onClose={onClose}><div className="modal-form"><strong>{prettyDate(commitment.date)}</strong><label>Actual start (HH:MM)<input value={start} onChange={(event)=>setStart(event.target.value)} inputMode="numeric"/></label><label>Actual end (HH:MM)<input value={end} onChange={(event)=>setEnd(event.target.value)} inputMode="numeric"/></label><div className="calculated-hours"><span>Automatically calculated</span><strong>{displayRange(start,end,timeDisplay)} · {hours} hours</strong></div>{placement?<div className="field-note">{placement.name} / {preceptor?.name}<br/>Completed Hours may exceed the planned duration or Target Hours; excess remains Over-Target Hours.</div>:null}</div><div className="modal-actions">{commitment.status==='awaiting-confirmation'?<button className="primary" onClick={()=>save('completed')}>Confirm {hours} Completed Hours</button>:<button className="primary" onClick={()=>save(commitment.status)}>Save corrected times</button>}{commitment.type==='clinical'&&(commitment.status==='scheduled'||commitment.status==='awaiting-confirmation')?<><button onClick={()=>onAction('cancelled')}>Cancel session</button><button onClick={()=>onAction('missed')}>Mark missed</button></>:null}<button className="danger-action" onClick={()=>onAction('delete')}><Trash2/> Delete erroneous entry</button></div></PanelModal>;
}

export function CommitmentModal({ commitment, placements, onSave, onAction, onClose, onBack, timeDisplay = 'Military time' }) {
  const placement = placements.find((item) => item.id === commitment.placementId);
  const preceptor = placement?.preceptors.find((person) => person.id === commitment.preceptorId);
  const [startValue,endValue] = commitment.time.split('-');
  const [start,setStart] = useState(startValue);
  const [end,setEnd] = useState(endValue);
  const [date,setDate] = useState(commitment.date);
  const hours = calculateHours(start,end);
  const save = (status) => onSave({ date, hours, time:`${start}-${end}`, status });
  return <PanelModal title={commitment.type === 'clinical' ? 'Clinical Session' : 'Work Shift'} onClose={onClose} onBack={onBack}><div className="modal-form"><label>Commitment date<input type="date" value={date} onChange={(event) => setDate(event.target.value)}/><small className="field-help">Change the date to move this entry. Its details and history stay attached.</small></label><div className="commitment-time-row"><FlexibleTimeField label="Actual start" value={start} onChange={setStart} preference={timeDisplay}/><FlexibleTimeField label="Actual end" value={end} onChange={setEnd} preference={timeDisplay}/><div className="calculated-hours"><span>Automatically calculated</span><strong>{displayRange(start,end,timeDisplay)} · {hours} hours</strong></div></div>{placement ? <div className="field-note">{placement.name} / {preceptor?.name}<br/>Completed Hours may exceed the planned duration or Target Hours; excess remains Over-Target Hours.</div> : null}</div><div className="modal-actions">{commitment.status === 'awaiting-confirmation' ? <button className="primary" onClick={() => save('completed')}>Confirm {hours} Completed Hours</button> : <button className="primary" onClick={() => save(commitment.status)}>{date === commitment.date ? 'Save corrected times' : 'Move and save commitment'}</button>}{commitment.type === 'clinical' && (commitment.status === 'scheduled' || commitment.status === 'awaiting-confirmation') ? <><button onClick={() => onAction('cancelled')}>Cancel session</button><button onClick={() => onAction('missed')}>Mark missed</button></> : null}<button className="danger-action" onClick={() => onAction('delete')}><Trash2/> Delete erroneous entry</button></div></PanelModal>;
}

function LegacySettingsModal({ settings, setSettings, templates, setTemplates, onClose, notify, onBack }) {
  const [draft, setDraft] = useState(settings);
  const [templateDrafts, setTemplateDrafts] = useState(templates.map((item) => ({...item})));
  const updateTemplate = (id, field, value) => setTemplateDrafts((all) => all.map((item) => item.id === id ? {...item,[field]:field === 'hours' ? Number(value) : value}:item));
  const addTemplate = () => setTemplateDrafts((all) => [...all,{id:`template-${Date.now()}`,name:'New Template',start:'07:00',end:'15:00',hours:8}]);
  const save = () => { setSettings(draft); setTemplates(templateDrafts); notify('Settings and schedule templates saved.'); onClose(); };
  return <PanelModal title="Settings" onClose={onClose} wide><div className="modal-form settings-form"><div className="settings-fields"><label>Week starts<select value={draft.weekStarts} onChange={(event) => setDraft({...draft,weekStarts:event.target.value})}><option>Sunday</option><option>Monday</option><option>Saturday</option></select></label><label>Time display<select value={draft.timeDisplay} onChange={(event) => setDraft({...draft,timeDisplay:event.target.value})}><option>Military time</option><option>12-hour time</option></select></label><label>Theme<select value={draft.theme} onChange={(event) => setDraft({...draft,theme:event.target.value})}><option>Borg Tactical Console</option><option>Star Trek Picard</option></select></label><label>Sync mode<select value={draft.syncMode} onChange={(event) => setDraft({...draft,syncMode:event.target.value})}><option>Local prototype</option><option>Google Drive folder</option><option>Managed account</option></select></label></div><div className="section-heading"><span><strong>Schedule templates</strong><small>Defaults can be changed for each Student.</small></span><button onClick={addTemplate}><Plus/> Add template</button></div>{templateDrafts.map((item) => <div className="template-editor" key={item.id}><input aria-label="Template name" value={item.name} onChange={(event) => updateTemplate(item.id,'name',event.target.value)}/><label>Start<input type="text" inputMode="numeric" pattern="[0-2][0-9]:[0-5][0-9]" placeholder="HH:MM" value={item.start} onChange={(event) => updateTemplate(item.id,'start',event.target.value)}/></label><label>End<input type="text" inputMode="numeric" pattern="[0-2][0-9]:[0-5][0-9]" placeholder="HH:MM" value={item.end} onChange={(event) => updateTemplate(item.id,'end',event.target.value)}/></label><label>Default hours<input type="number" min="0.25" step="0.25" value={item.hours} onChange={(event) => updateTemplate(item.id,'hours',event.target.value)}/></label>{templateDrafts.length > 1 ? <button className="icon-button danger-action" onClick={() => setTemplateDrafts((all) => all.filter((x) => x.id !== item.id))} aria-label={`Remove ${item.name}`}><Trash2/></button> : null}</div>)}</div><div className="modal-actions"><button className="primary" onClick={save}>Save settings</button></div></PanelModal>;
}

function CurrentSettingsModal({settings,setSettings,templates,setTemplates,onClose,notify,onBack}) {
  const [draft,setDraft]=useState(settings);
  const [templateDrafts,setTemplateDrafts]=useState(templates.map((item)=>({...item})));
  const update=(id,field,value)=>setTemplateDrafts((all)=>all.map((item)=>item.id===id?{...item,[field]:value}:item));
  const add=()=>setTemplateDrafts((all)=>[...all,{id:`template-${Date.now()}`,name:'New Template',start:'07:00',end:'15:00'}]);
  const save=()=>{setSettings(draft);setTemplates(templateDrafts.map((item)=>({...item,hours:calculateHours(item.start,item.end)})));notify('Settings and schedule templates saved.');onClose();};
  return <PanelModal title="Settings" onClose={onClose} onBack={onBack} wide><div className="modal-form settings-form"><div className="settings-fields"><label>Week starts<select value={draft.weekStarts} onChange={(event)=>setDraft({...draft,weekStarts:event.target.value})}><option>Sunday</option><option>Monday</option><option>Saturday</option></select></label><label>Time display<select value={draft.timeDisplay} onChange={(event)=>setDraft({...draft,timeDisplay:event.target.value})}><option>Military time</option><option>12-hour time</option></select></label><label>Theme<select value={draft.theme} onChange={(event)=>setDraft({...draft,theme:event.target.value})}><option>Borg Tactical Console</option><option>Star Trek Picard</option></select></label><label>Sync mode<select value={draft.syncMode} onChange={(event)=>setDraft({...draft,syncMode:event.target.value})}><option>Local prototype</option><option>Google Drive folder</option><option>Managed account</option></select></label></div><div className="section-heading"><span><strong>Schedule templates</strong><small>Edit saved template times here. The scheduling tray only adjusts the current batch.</small></span><button onClick={add}><Plus/> Add template</button></div>{templateDrafts.map((item)=><div className="template-editor auto-hours" key={item.id}><input aria-label="Template name" value={item.name} onChange={(event)=>update(item.id,'name',event.target.value)}/><label>Start (HH:MM)<input value={item.start} onChange={(event)=>update(item.id,'start',event.target.value)} inputMode="numeric"/></label><label>End (HH:MM)<input value={item.end} onChange={(event)=>update(item.id,'end',event.target.value)} inputMode="numeric"/></label><div className="calculated-hours"><span>Displays as</span><strong>{displayRange(item.start,item.end,draft.timeDisplay)}</strong><small>{calculateHours(item.start,item.end)} hours automatically</small></div>{templateDrafts.length>1?<button className="icon-button danger-action" onClick={()=>setTemplateDrafts((all)=>all.filter((other)=>other.id!==item.id))} aria-label={`Remove ${item.name}`}><Trash2/></button>:null}</div>)}</div><div className="modal-actions"><button className="primary" onClick={save}>Save settings</button></div></PanelModal>;
}

export function SettingsModal({ settings, setSettings, templates, setTemplates, onClose, notify, onBack }) {
  const [draft,setDraft] = useState(settings);
  const [templateDrafts,setTemplateDrafts] = useState(templates.map((item) => ({...item})));
  const update = (id,field,value) => setTemplateDrafts((all) => all.map((item) => item.id === id ? {...item,[field]:value} : item));
  const add = () => setTemplateDrafts((all) => [...all,{id:`template-${Date.now()}`,name:'New Template',start:'07:00',end:'15:00'}]);
  const save = () => {
    setSettings(draft);
    setTemplates(templateDrafts.map((item) => ({...item,hours:calculateHours(item.start,item.end)})));
    notify('Settings and schedule templates saved.');
    onClose();
  };
  return <PanelModal title="Settings" onClose={onClose} onBack={onBack} wide><div className="modal-form settings-form"><div className="settings-fields"><label>Week starts<select value={draft.weekStarts} onChange={(event) => setDraft({...draft,weekStarts:event.target.value})}><option>Sunday</option><option>Monday</option><option>Saturday</option></select></label><label>Time display<select value={draft.timeDisplay} onChange={(event) => setDraft({...draft,timeDisplay:event.target.value})}><option>Military time</option><option>12-hour time</option></select></label><label>Theme<select value={draft.theme} onChange={(event) => setDraft({...draft,theme:event.target.value})}><option>Borg Tactical Console</option><option>Star Trek Picard</option></select></label><label>Sync mode<select value={draft.syncMode} onChange={(event) => setDraft({...draft,syncMode:event.target.value})}><option>Local prototype</option><option>Google Drive folder</option><option>Managed account</option></select></label></div><div className="section-heading"><span><strong>Schedule templates</strong><small>Edit saved template times here. The scheduling tray only adjusts the current batch.</small></span><button onClick={add}><Plus/> Add template</button></div>{templateDrafts.map((item) => <div className="template-editor auto-hours" key={item.id}><input aria-label="Template name" value={item.name} onChange={(event) => update(item.id,'name',event.target.value)}/><FlexibleTimeField label={`${item.name} start`} value={item.start} onChange={(value) => update(item.id,'start',value)} preference={draft.timeDisplay}/><FlexibleTimeField label={`${item.name} end`} value={item.end} onChange={(value) => update(item.id,'end',value)} preference={draft.timeDisplay}/><div className="calculated-hours"><span>Displays as</span><strong>{displayRange(item.start,item.end,draft.timeDisplay)}</strong><small>{calculateHours(item.start,item.end)} hours automatically</small></div>{templateDrafts.length > 1 ? <button className="icon-button danger-action" onClick={() => setTemplateDrafts((all) => all.filter((other) => other.id !== item.id))} aria-label={`Remove ${item.name}`}><Trash2/></button> : null}</div>)}</div><div className="modal-actions"><button className="primary" onClick={save}>Save settings</button></div></PanelModal>;
}

export function PlacementSettings({ placements, setPlacements, selectedPlacement, onSelectPlacement, onClose, notify, onBack }) {
  const [selected, setLocalSelected] = useState(() => placements.some((item) => item.id === selectedPlacement) ? selectedPlacement : placements[0].id);
  const setSelected = (id) => { setLocalSelected(id); onSelectPlacement(id); };
  const active = placements.find((item) => item.id === selected);
  const update = (change) => setPlacements((all) => all.map((item) => item.id === selected ? change(item) : item));
  const addPlacement = () => {
    const id = `placement-${Date.now()}`;
    setPlacements((all) => [...all,{id,name:'New Clinical Placement',target:90,reviewCadence:90,evaluationPlan:{initialSelf:true,finalSelf:true,finalPlacement:true},completed:0,icon:'stethoscope',preceptors:[{id:`preceptor-${Date.now()}`,name:'New Preceptor',primary:true,completed:0}]}]);
    setSelected(id); notify('New Clinical Placement added and selected.');
  };
  const setEvaluationRequirement = (key, value) => update((item) => ({...item,evaluationPlan:{initialSelf:true,finalSelf:true,finalPlacement:true,...item.evaluationPlan,[key]:value === 'Required'}}));
  const evaluationValue = (key) => active.evaluationPlan?.[key] === false ? 'Not required' : 'Required';
  return <PanelModal title="Clinical Placement management" onClose={onClose} onBack={onBack} wide><div className="settings-grid"><nav>{placements.map((item) => <button className={item.id === selected ? 'active' : ''} key={item.id} onClick={() => setSelected(item.id)}>{item.name}</button>)}<button onClick={addPlacement}><Plus/> Add placement</button></nav><div className="modal-form"><label>Placement name<input value={active.name} onChange={(event) => update((item) => ({...item,name:event.target.value}))}/></label><label>Target Hours<input type="number" min="1" value={active.target} onChange={(event) => update((item) => ({...item,target:Number(event.target.value)||1}))}/></label><h3>Evaluation Plan</h3><label>Interim Review cadence (hours)<input type="number" min="1" step="1" value={active.reviewCadence || 90} onChange={(event) => update((item) => ({...item,reviewCadence:Number(event.target.value)||1}))}/></label><small>Medatrax thresholds repeat at this interval. Your current requirement is every 90 Completed Hours.</small><div className="evaluation-plan-grid"><label>Initial Self-Evaluation<select value={evaluationValue('initialSelf')} onChange={(event) => setEvaluationRequirement('initialSelf',event.target.value)}><option>Required</option><option>Not required</option></select></label><label>Final Self-Evaluation<select value={evaluationValue('finalSelf')} onChange={(event) => setEvaluationRequirement('finalSelf',event.target.value)}><option>Required</option><option>Not required</option></select></label><label>Final Clinical Placement Review<select value={evaluationValue('finalPlacement')} onChange={(event) => setEvaluationRequirement('finalPlacement',event.target.value)}><option>Required</option><option>Not required</option></select></label></div><small>These requirements control which beginning and end-of-placement items appear in this placement's Evaluation checklist.</small><h3>Preceptors</h3>{active.preceptors.map((person) => <div className="preceptor-editor" key={person.id}><input aria-label="Preceptor name" value={person.name} onChange={(event) => update((item) => ({...item,preceptors:item.preceptors.map((other) => other.id === person.id ? {...other,name:event.target.value}:other)}))}/><button className={person.primary ? 'primary':''} onClick={() => update((item) => ({...item,preceptors:item.preceptors.map((other) => ({...other,primary:other.id === person.id}))}))}>{person.primary ? 'Primary Preceptor':'Set Primary'}</button>{!person.primary ? <button className="icon-button danger-action" aria-label={`Remove ${person.name}`} onClick={() => update((item) => ({...item,preceptors:item.preceptors.filter((other) => other.id !== person.id)}))}><Trash2/></button>:null}</div>)}<button onClick={() => update((item) => ({...item,preceptors:[...item.preceptors,{id:`preceptor-${Date.now()}`,name:'New Preceptor',primary:false,completed:0}]}))}><Plus/> Add Preceptor</button><small>Changing the Primary Preceptor preserves Completed Hours, Over-Target Hours, and documented review history.</small></div></div></PanelModal>;
}
