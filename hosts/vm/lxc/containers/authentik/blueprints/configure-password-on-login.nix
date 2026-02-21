{
  name = "configure-password-on-login";
  content = ''
    version: 1
    metadata:
      name: First Login Password Setup
    entries:
      # === POLICIES ===
      
      # Show password stage only if user HAS a password
      - model: authentik_policies_expression.expressionpolicy
        id: policy-has-usable-password
        identifiers:
          name: policy-has-usable-password
        attrs:
          expression: |
            pending_user = request.context.get("pending_user")
            if not pending_user:
                return True
            return pending_user.has_usable_password()

      # Show setup stage only if user has NO password
      - model: authentik_policies_expression.expressionpolicy
        id: policy-needs-password-setup
        identifiers:
          name: policy-needs-password-setup
        attrs:
          expression: |
            pending_user = request.context.get("pending_user")
            if not pending_user:
                return False
            return not pending_user.has_usable_password()

      # === PROMPTS ===
      
      - model: authentik_stages_prompt.prompt
        id: prompt-password
        identifiers:
          field_key: password
        attrs:
          name: prompt-password
          label: Create Password
          type: password
          required: true
          order: 0

      - model: authentik_stages_prompt.prompt
        id: prompt-password-repeat
        identifiers:
          field_key: password_repeat
        attrs:
          name: prompt-password-repeat
          label: Confirm Password
          type: password
          required: true
          order: 1

      # === STAGES ===
      
      - model: authentik_stages_identification.identificationstage
        id: stage-identification
        identifiers:
          name: first-login-identification
        attrs:
          user_fields:
            - username
            - email
          show_matched_user: true
          pretend_user_exists: true

      - model: authentik_stages_password.passwordstage
        id: stage-password
        identifiers:
          name: first-login-password
        attrs:
          backends:
            - authentik.core.auth.InbuiltBackend
          failed_attempts_before_cancel: 5

      - model: authentik_stages_prompt.promptstage
        id: stage-initial-password-setup
        identifiers:
          name: stage-initial-password-setup
        attrs:
          fields:
            - !KeyOf prompt-password
            - !KeyOf prompt-password-repeat

      - model: authentik_stages_user_write.userwritestage
        id: stage-write-initial-password
        identifiers:
          name: stage-write-initial-password
        attrs:
          user_creation_mode: never_create

      - model: authentik_stages_user_login.userloginstage
        id: stage-user-login
        identifiers:
          name: first-login-user-login
        attrs:
          terminate_other_sessions: false

      # === FLOW ===
      
      - model: authentik_flows.flow
        id: flow-first-login-authentication
        identifiers:
          slug: first-login-authentication
        attrs:
          name: First Login Authentication
          title: Welcome
          designation: authentication

      # === FLOW STAGE BINDINGS ===
      
      - model: authentik_flows.flowstagebinding
        id: binding-identification
        identifiers:
          target: !KeyOf flow-first-login-authentication
          stage: !KeyOf stage-identification
        attrs:
          order: 0

      - model: authentik_flows.flowstagebinding
        id: binding-password
        identifiers:
          target: !KeyOf flow-first-login-authentication
          stage: !KeyOf stage-password
        attrs:
          order: 10
          evaluate_on_plan: false
          re_evaluate_policies: true

      - model: authentik_flows.flowstagebinding
        id: binding-initial-password-setup
        identifiers:
          target: !KeyOf flow-first-login-authentication
          stage: !KeyOf stage-initial-password-setup
        attrs:
          order: 20
          evaluate_on_plan: false
          re_evaluate_policies: true

      - model: authentik_flows.flowstagebinding
        id: binding-write-initial-password
        identifiers:
          target: !KeyOf flow-first-login-authentication
          stage: !KeyOf stage-write-initial-password
        attrs:
          order: 21
          evaluate_on_plan: false
          re_evaluate_policies: true

      - model: authentik_flows.flowstagebinding
        id: binding-user-login
        identifiers:
          target: !KeyOf flow-first-login-authentication
          stage: !KeyOf stage-user-login
        attrs:
          order: 30

      # === POLICY BINDINGS ===
      
      - model: authentik_policies.policybinding
        identifiers:
          target: !KeyOf binding-password
          policy: !KeyOf policy-has-usable-password
        attrs:
          order: 0
          enabled: true

      - model: authentik_policies.policybinding
        identifiers:
          target: !KeyOf binding-initial-password-setup
          policy: !KeyOf policy-needs-password-setup
        attrs:
          order: 0
          enabled: true

      - model: authentik_policies.policybinding
        identifiers:
          target: !KeyOf binding-write-initial-password
          policy: !KeyOf policy-needs-password-setup
        attrs:
          order: 0
          enabled: true

      # === BRAND ASSIGNMENT ===
      
      - model: authentik_brands.brand
        identifiers:
          domain: authentik-default
        attrs:
          flow_authentication: !KeyOf flow-first-login-authentication
        state: present
  '';
}
