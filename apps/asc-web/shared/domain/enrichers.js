// Domain: Enrich raw data with semantic booleans + affordances
// In REST mode, server responses already contain _links — use them directly.
// In CLI/mock mode, generate affordances client-side as before.
import { VersionState } from './version-state.js';
import {
  appAffordances, versionAffordances, buildAffordances,
  betaGroupAffordances, reviewAffordances, iapAffordances,
  subGroupAffordances, subscriptionAffordances, bundleIdAffordances,
  certAffordances, profileAffordances, teamMemberAffordances,
  invitationAffordances, xcProductAffordances, xcWorkflowAffordances,
  xcBuildRunAffordances,
} from './affordances.js';

/// If the server already provided _links (REST mode), convert them to the
/// affordances format the UI expects. Otherwise fall back to client-side generation.
function resolveAffordances(raw, fallbackFn) {
  if (raw._links) return raw._links;
  if (raw.affordances) return raw.affordances;
  return fallbackFn(raw);
}

export function enrichApp(raw) {
  return { ...raw, displayName: raw.name || raw.bundleId, affordances: resolveAffordances(raw, appAffordances) };
}

export function enrichVersion(raw) {
  return {
    ...raw,
    isLive: VersionState.isLive(raw.state),
    isEditable: VersionState.isEditable(raw.state),
    isPending: VersionState.isPending(raw.state),
    affordances: resolveAffordances(raw, versionAffordances),
  };
}

export function enrichBuild(raw) {
  const isUsable = !raw.expired && raw.processingState === 'VALID';
  return { ...raw, isUsable, affordances: resolveAffordances(raw, (r) => buildAffordances({ ...r, isUsable })) };
}

export function enrichBetaGroup(raw)  { return { ...raw, affordances: resolveAffordances(raw, betaGroupAffordances) }; }
export function enrichReview(raw)     { return { ...raw, affordances: resolveAffordances(raw, reviewAffordances) }; }

export function enrichIAP(raw) {
  const isLive = raw.state === 'APPROVED';
  const isEditable = ['MISSING_METADATA','REJECTED','DEVELOPER_ACTION_NEEDED'].includes(raw.state);
  return { ...raw, isLive, isEditable, affordances: resolveAffordances(raw, iapAffordances) };
}

export function enrichSubGroup(raw)   { return { ...raw, affordances: resolveAffordances(raw, subGroupAffordances) }; }

export function enrichSubscription(raw) {
  const isLive = raw.state === 'APPROVED';
  const isEditable = ['MISSING_METADATA','REJECTED','DEVELOPER_ACTION_NEEDED'].includes(raw.state);
  return { ...raw, isLive, isEditable, affordances: resolveAffordances(raw, subscriptionAffordances) };
}

export function enrichBundleId(raw)   { return { ...raw, affordances: resolveAffordances(raw, bundleIdAffordances) }; }

export function enrichCert(raw) {
  const isExpired = raw.expirationDate ? new Date(raw.expirationDate) < new Date() : false;
  return { ...raw, isExpired, affordances: resolveAffordances(raw, certAffordances) };
}

export function enrichProfile(raw) {
  const isActive = raw.profileState === 'ACTIVE';
  return { ...raw, isActive, affordances: resolveAffordances(raw, profileAffordances) };
}

export function enrichTeamMember(raw) { return { ...raw, affordances: resolveAffordances(raw, teamMemberAffordances) }; }
export function enrichInvitation(raw) { return { ...raw, affordances: resolveAffordances(raw, invitationAffordances) }; }
export function enrichXCProduct(raw)  { return { ...raw, affordances: resolveAffordances(raw, xcProductAffordances) }; }
export function enrichXCWorkflow(raw) { return { ...raw, affordances: resolveAffordances(raw, xcWorkflowAffordances) }; }

export function enrichXCBuildRun(raw) {
  const ep = raw.executionProgress;
  return {
    ...raw,
    isPending: ep === 'PENDING', isRunning: ep === 'RUNNING', isComplete: ep === 'COMPLETE',
    isSucceeded: raw.completionStatus === 'SUCCEEDED',
    hasFailed: ['FAILED','ERRORED'].includes(raw.completionStatus),
    affordances: resolveAffordances(raw, xcBuildRunAffordances),
  };
}
