export const VERSION = "2.0.0";

export const CONFIG = {
  /** Optional hard-coded org URL for local testing; normally resolved from Xrm. */
  clientUrl: "",
  /** Environment id used to build Copilot Studio / Power Automate deep links. */
  environmentId: "",

  configTable: {
    entitySet: "pda_monitoredagents",
    idCol: "pda_monitoredagentid",
    nameCol: "pda_name",
    typeCol: "pda_agenttype",
    targetCol: "pda_targetid",
    triggerUrlCol: "pda_triggerurl",
    scopeCol: "pda_scope",
    typeValues: { copilot: 100000000, autonomous: 100000001 },
    scopeValues: { initiative: 100000000, program: 100000001, portfolio: 100000002 }
  },

  // Tables the project-picker dialog browses, one per pda_scope value. The
  // selected record's id is bound to the matching lookup column on pda_agentruns.
  scopeTables: {
    initiative: {
      entitySet: "pum_initiatives",
      idCol: "pum_initiativeid",
      nameCol: "pum_name",
      runLookupCol: "pda_Initiative"
    },
    program: {
      entitySet: "pum_programs",
      idCol: "pum_programid",
      nameCol: "pum_program",
      runLookupCol: "pda_Program"
    },
    portfolio: {
      entitySet: "pum_portfolios",
      idCol: "pum_portfolioid",
      nameCol: "pum_portfolio",
      runLookupCol: "pda_Portfolio"
    }
  },

  // Contract table the agent workflow writes its step/approval rows into.
  // See README "Workflow author contract".
  actionTable: {
    entitySet: "pda_agentactions",
    idCol: "pda_agentactionid",
    nameCol: "pda_name",
    agentIdCol: "pda_agentid",
    runIdCol: "pda_runid",
    typeCol: "pda_actiontype",
    statusCol: "pda_status",
    detailCol: "pda_detail",
    responseCol: "pda_response",
    responseOptionCol: "pda_responseoption",
    startCol: "pda_starttime",
    endCol: "pda_endtime",
    typeValues: { step: 100000000, approval: 100000001, input: 100000002 },
    statusValues: { running: 100000000, completed: 100000001, failed: 100000002, waiting: 100000003 },
    responseValues: { approved: 100000000, rejected: 100000001 }
  },

  // Custom Dataverse table used to fire an agent: the dashboard creates a row here,
  // and the agent workflow's Dataverse trigger ("When a row is added") reacts to it
  // with a filter on the monitored agent lookup. No HTTP trigger, no OAuth, no secrets.
  // createdby/modifiedby land on the row as the real signed-in user.
  fireTable: {
    entitySet: "pda_agentruns",
    idCol: "pda_agentrunid",
    nameCol: "pda_name",
    messageCol: "pda_message",
    agentCol: "pda_xPMAgent",
    statusCol: "pda_status"
  },

  features: {
    /** Native msdyn_flow_approval* integration — validate in env before enabling. */
    msdynApprovals: false
  },

  runsPerAgent: 50,
  agentsRefreshSeconds: 60,
  actionsRefreshMs: 5000,
  demoActionsRefreshMs: 1000,
  approvalsRefreshMs: 10000,
  fireConfirmTimeoutMs: 60000,
  fireConfirmPollMs: 5000
};

export type Config = typeof CONFIG;
