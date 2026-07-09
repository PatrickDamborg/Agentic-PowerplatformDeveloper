import { api, apiPost } from "../../api/dataverse";

/**
 * STRETCH — behind CONFIG.features.msdynApprovals (default OFF).
 *
 * Microsoft's own approvals (the Approvals connector) live in Dataverse:
 *   msdyn_flow_approvals / msdyn_flow_approvalrequests / msdyn_flow_approvalresponses
 * Reading pending approvals for the current user works via the Web API.
 * Completing one by POSTing an msdyn_flow_approvalresponse row is
 * community-proven but NOT yet validated in this environment — validate
 * before flipping the flag (see README "Tomorrow" checklist).
 *
 * The new Workflows "request information" action is Outlook-only and does not
 * use these tables; this provider only covers Approvals-connector approvals.
 */
export async function loadMsdynPendingApprovals(): Promise<any[]> {
  const data = await api(
    `msdyn_flow_approvals?$select=msdyn_flow_approvalid,msdyn_flow_approval_title,createdon` +
      `&$filter=statuscode eq 192350001&$orderby=createdon desc&$top=25`
  );
  return data.value as any[];
}

export async function respondToMsdynApproval(
  approvalId: string,
  approve: boolean,
  comments: string
): Promise<void> {
  await apiPost("msdyn_flow_approvalresponses", {
    "msdyn_flow_approvalresponse_approval@odata.bind": `/msdyn_flow_approvals(${approvalId})`,
    msdyn_flow_approvalresponse_response: JSON.stringify({
      response: approve ? "Approve" : "Reject",
      comments
    })
  });
}
