# Clinical Calendar

This context describes a personal clinical-training calendar that helps a student schedule work and clinical activity while tracking required placement hours.

## Language

**Student**:
The person who owns one account and every piece of data entered under it. Many Students may use the same hosted application, but each sees and edits only their own calendar; nothing is shared between Students. Preceptors, schools, and coordinators do not operate the application.
_Avoid_: User, learner

**Academic Assignment**:
A course deliverable owned by the Student with a title, class or course, required Due Date, and Pending or Completed status. It is distinct from assigning a Clinical Session to a Clinical Placement and Preceptor.
_Avoid_: Assignment alone, clinical assignment, placement assignment

**Class Catalog Entry**:
A reusable class or course owned by the Student and selected by Academic Assignments. Archiving removes it from new selections without erasing it from existing Academic Assignments; renaming it updates linked assignment projections.
_Avoid_: Course record, subject, Academic Assignment class

**Clinical Placement**:
A program requirement with a defined target number of hours, Start Date, and Completion Deadline, such as Family Medicine with a 270-hour target. It persists independently of any particular Preceptor or clinical site, so changing either never resets its progress.
_Avoid_: Preceptorship, rotation

**Ready to Complete**:
The state of a Clinical Placement that has met its target, has every Evaluation Plan requirement documented, and has no unresolved past or scheduled future Clinical Sessions.
_Avoid_: Complete, finished

**Completed Placement**:
A Ready-to-Complete Clinical Placement the Student has explicitly closed.
_Avoid_: Ready to complete, archived placement

**Preceptor**:
A person who supervises the Student for some or all scheduled activity within a Clinical Placement.
_Avoid_: Supervisor, provider

**Primary Preceptor**:
The Preceptor designated as the main supervising person for a Clinical Placement; other Preceptors may also supervise activity in that placement. Interim Reviews involve this Preceptor regardless of who supervised the contributing hours.
_Avoid_: Main preceptor

**Evaluation Plan**:
The configurable set of assessment and review requirements attached to a Clinical Placement.
_Avoid_: Review schedule, milestone settings

**Initial Self-Assessment**:
The Student's evaluation of themself required before a Clinical Placement begins.
_Avoid_: Preceptor review, initial review

**Interim Review**:
A recurring two-part requirement triggered at configurable Completed Hours thresholds: the Student reviews the Primary Preceptor, and the Primary Preceptor reviews the Student. The threshold uses combined hours across all Preceptors, and each part is documented separately.
_Avoid_: Review Milestone, final review

**Final Self-Assessment**:
The Student's evaluation of themself required at the end of a Clinical Placement.
_Avoid_: Final Placement Review

**Final Placement Review**:
The Student's evaluation of the overall Clinical Placement required at its end.
_Avoid_: Final Self-Assessment, preceptor evaluation

**Completed Hours**:
Clinical Placement time that the Student has already worked and explicitly marked complete. It equals the exact elapsed minutes between the confirmed actual start and end, with no break deduction or automatic rounding.
_Avoid_: Earned hours

**Scheduled Hours**:
Planned Clinical Placement time in future or past Scheduled Sessions; overdue time remains scheduled while awaiting confirmation and does not count as Completed Hours.
_Avoid_: Planned completion

**Remaining Hours**:
The Clinical Placement target minus Completed Hours, floored at zero; it includes both scheduled and unscheduled time still to be worked.
_Avoid_: Hours left to schedule

**Unscheduled Hours**:
The Clinical Placement target minus both Completed Hours and Scheduled Hours, floored at zero.
_Avoid_: Remaining hours

**Over-Target Hours**:
Completed Hours beyond a Clinical Placement's target. They remain valid and are reported separately rather than making Remaining Hours negative.
_Avoid_: Extra hours, excess hours

**Historical Hours Entry**:
An aggregate record of Clinical Placement hours completed before the Student began tracking individual Clinical Sessions in the application. It may identify one Preceptor or remain Unattributed, and it contributes to Completed Hours and Interim Review thresholds without becoming a timed calendar commitment.
_Avoid_: Imported session, manual adjustment

**Protected Day**:
One day selected independently for each calendar week and reserved for the Student's rest and preparation. It may remain temporarily unselected while a month is being planned, but a completed monthly plan requires one for every week. The Student cannot place Work Shifts or clinical activity on it; an Imported Work Shift that lands on it is a flagged Schedule Conflict.
_Avoid_: Preferred day off, availability

**Work Shift**:
A time-zone-specific military-time calendar commitment representing the Student's employment schedule. The Student either enters it by hand or receives it as an Imported Work Shift.
_Avoid_: Work session, job event

**Work Schedule Feed**:
An optional private calendar subscription the Student connects so that an employer's scheduling system supplies their Work Shifts. Every event it publishes is treated as work; personal calendars are not Work Schedule Feeds.
_Avoid_: Calendar sync, integration, import

**Imported Work Shift**:
A Work Shift that mirrors an event in a Work Schedule Feed. The feed is its only owner: it is read-only to the Student and, until it starts, changes or disappears when the feed does. Once it has started it is frozen as history, even if the feed later stops listing it.
_Avoid_: Synced shift, copied shift

**Clinical Session**:
A time-zone-specific military-time calendar commitment assigned to one Clinical Placement and one Preceptor.
_Avoid_: Clinical shift, appointment

**Scheduled Session**:
A Clinical Session planned for the future, or awaiting confirmation after its end time; its planned duration contributes to Scheduled Hours until resolved.
_Avoid_: Upcoming session

**Completed Session**:
A Clinical Session the Student explicitly confirms as worked; its confirmed actual duration contributes to Completed Hours.
_Avoid_: Past session

**Cancelled Session**:
A Clinical Session cancelled in advance and retained in history without contributing hours.
_Avoid_: Deleted session

**Missed Session**:
A Clinical Session the Student did not attend and that is retained in history without contributing hours.
_Avoid_: Cancelled session

**Connected Device**:
One signed-in installation of the application registered to synchronize the Student's data: a Windows, iPhone, or Android app, or a single web browser. The Student can revoke it, after which it can no longer synchronize.
_Avoid_: Session, login, client

**Ticket**:
What a Student puts in to tell the Maintainer something about the application: that something's wrong, an idea, or a question. It stays private between the sender and the Maintainer; publishing anything about it to the public issue tracker is a separate, deliberate act that never quotes it. The sender can follow it from sent, to seen, to done or won't do, and is told why when it closes.
_Avoid_: Report (in clinical settings, report is the patient handover), feedback, bug, issue

**Maintainer**:
The person who builds the application and reads Tickets. Being the Maintainer is a grant on their own Student account, not a second account, and it gives no access to any Student's calendar data.
_Avoid_: Admin, support, developer

**Schedule Conflict**:
An overlap between calendar commitments, or a commitment on a Protected Day. The Student can never create one. An Imported Work Shift can reveal one, because the employer's schedule is a fact; the conflict then stays flagged until the Student resolves it.
_Avoid_: Warning, double booking
