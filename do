@Override
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {

    KeycloakSecurityContext kscRequest = (KeycloakSecurityContext) request.getAttribute(KeycloakSecurityContext.class.getName());
    securityLog.info("Keycloak context in request is: " + kscRequest);

    var authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication != null && authentication.getPrincipal() != null) {
        Object principal = authentication.getPrincipal();

        DBLegiUser user = null;

        if (principal instanceof DBLegiUser) {
            user = (DBLegiUser) principal;
        } else if (principal instanceof org.springframework.security.oauth2.core.oidc.user.OidcUser) {
            // Optionally map OidcUser to your DBLegiUser here
            org.springframework.security.oauth2.core.oidc.user.OidcUser oidcUser = (org.springframework.security.oauth2.core.oidc.user.OidcUser) principal;
            user = mapOidcUserToDBLegiUser(oidcUser); // implement this mapping method
        } else if (principal instanceof org.springframework.security.core.userdetails.User) {
            // If default UserDetails used, fetch your DBLegiUser by username
            String username = ((org.springframework.security.core.userdetails.User) principal).getUsername();
            user = yourUserService.loadUserByUsername(username); // implement this lookup
        } else if (principal instanceof String) {
            // If principal is just a String (username)
            user = yourUserService.loadUserByUsername((String) principal); // implement as needed
        }

        if (user != null) {
            KeycloakSecurityContext kscSecContext = user.getKeycloakSecurityContext();
            if (kscSecContext != null && kscRequest != null && kscSecContext != kscRequest) {
                securityLog.info("Setting new ksc context: " + kscRequest);
                user.setKeycloakSecurityContext(kscRequest);
            }
        } else {
            securityLog.warn("No DBLegiUser instance could be resolved from principal");
        }
    }

    chain.doFilter(request, response);
}
