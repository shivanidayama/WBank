@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true) // replaces @EnableGlobalMethodSecurity
public class WebSecurityConfig {

    @Value("${use.dummy.preauth:true}")
    private boolean useDummySSO;

    @Value("${use.dummy.user:unknown}")
    private String dummySSOUserEmail;

    @Value("${lsl.session-timeout}")
    private Integer sessionTimeout;

    @Value("${lsl.test:false}")
    private Boolean test;

    private static final Logger securityLog =
            LoggerFactory.getLogger("technical." + WebSecurityConfig.class.getName());

    private final DbLUserDetailsServiceImpl userDetailsService;
    private final Environment env;

    public WebSecurityConfig(DbLUserDetailsServiceImpl userDetailsService, Environment env) {
        this.userDetailsService = userDetailsService;
        this.env = env;
    }

    @Bean
    public AuthenticationManager authenticationManager(HttpSecurity http) throws Exception {
        return http.getSharedObject(AuthenticationManagerBuilder.class)
                .authenticationProvider(preauthenticatedProvider())
                .build();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .exceptionHandling(ex -> ex.authenticationEntryPoint(entryPoint()))
            .authorizeHttpRequests(auth -> auth
                    .requestMatchers("/staticResources/**", "/session/**").authenticated()
                    .anyRequest().authenticated()
            )
            .csrf(csrf -> csrf.disable())
            .addFilter(preAuthenticationFilter(entryPoint()))
            .addFilterAfter(new SessionExpiredFilterImpl(),
                    AbstractPreAuthenticatedProcessingFilter.class)
            .headers(h -> h.cacheControl(Customizer.withDefaults()))
            .sessionManagement(session -> session
                    .maximumSessions(1)
                    .sessionRegistry(sessionRegistry())
                    .expiredUrl("/sessionExpired")
                    .maxSessionsPreventsLogin(true)
                    .and()
                    .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                    .invalidSessionUrl("/sessionExpired")
            );

        return http.build();
    }

    @Bean
    public SessionRegistry sessionRegistry() {
        return new SessionRegistryImpl();
    }

    @Bean
    public HttpSessionEventPublisher httpSessionEventPublisher() {
        return new HttpSessionEventPublisher();
    }

    @Bean
    public PreAuthenticatedAuthenticationProvider preauthenticatedProvider() {
        PreAuthenticatedAuthenticationProvider authProvider = new PreAuthenticatedAuthenticationProvider();
        authProvider.setPreAuthenticatedUserDetailsService(userDetailsServiceWrapper());
        return authProvider;
    }

    @Bean
    public AuthenticationEntryPoint entryPoint() {
        return new CustomAuthenticationEntryPoint();
    }

    @Bean
    public AbstractPreAuthenticatedProcessingFilter preAuthenticationFilter(AuthenticationEntryPoint entryPoint)
            throws Exception {
        AbstractPreAuthenticatedProcessingFilter filter = new AbstractPreAuthenticatedProcessingFilter() {
            @Override
            protected Object getPreAuthenticatedPrincipal(HttpServletRequest request) {
                KeycloakSecurityContext securityContext =
                        (KeycloakSecurityContext) request.getAttribute(KeycloakSecurityContext.class.getName());

                securityLog.info(String.format("KeycloakSecurityContext: %s %s", securityContext, request.getRequestURI()));

                if (securityContext != null) {
                    securityLog.info(String.format("AccessToken <<%s>>: %s",
                            securityContext.getToken().getId(),
                            securityContext.getTokenString()));
                }
                return securityContext != null ? securityContext.getTokenString() : null;
            }

            @Override
            protected Object getPreAuthenticatedCredentials(HttpServletRequest request) {
                return "pass";
            }
        };
        filter.setAuthenticationManager(authenticationManager(null));
        return filter;
    }

    @Bean
    public FilterRegistrationBean<AbstractPreAuthenticatedProcessingFilter> registration(AbstractPreAuthenticatedProcessingFilter filter) {
        FilterRegistrationBean<AbstractPreAuthenticatedProcessingFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public UserDetailsService userDetailsService() {
        return this.userDetailsService;
    }

    @Bean
    public UserDetailsByNameServiceWrapper<PreAuthenticatedAuthenticationToken> userDetailsServiceWrapper() {
        UserDetailsByNameServiceWrapper<PreAuthenticatedAuthenticationToken> wrapper =
                new UserDetailsByNameServiceWrapper<>();
        wrapper.setUserDetailsService(userDetailsService());
        return wrapper;
    }

    @Bean
    public HttpSessionListener httpSessionListener() {
        return new LccHttpSessionListener(sessionTimeout);
    }

    @Bean
    public FilterRegistrationBean<KeycloakOIDCFilter> keycloakFilter() {
        KeycloakOIDCFilter filter = new KeycloakOIDCFilter();
        FilterRegistrationBean<KeycloakOIDCFilter> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(filter);
        registrationBean.addUrlPatterns("/*");
        registrationBean.setOrder(Ordered.HIGHEST_PRECEDENCE + 1);

        KeycloakConfigurationResolver.env = env;

        registrationBean.addInitParameter(KeycloakOIDCFilter.CONFIG_RESOLVER_PARAM,
                KeycloakConfigurationResolver.class.getName());
        registrationBean.addInitParameter("keycloak.config.skipPattern",
                "./.*(bff/.*|refreshSession|version|monitor.*|js|css|ico|png|svg|woff2|woff|eot|ttf|accessDenied.*|sessionExpired.*)");

        return registrationBean;
    }

    @Bean
    public FilterRegistrationBean<SessionEqualizeFilter> sessionEqualizer() {
        FilterRegistrationBean<SessionEqualizeFilter> registrationBean = new FilterRegistrationBean<>();
        SessionEqualizeFilter filter = new SessionEqualizeFilter();
        registrationBean.setFilter(filter);
        registrationBean.addUrlPatterns("/*");
        registrationBean.setOrder(Ordered.LOWEST_PRECEDENCE);
        return registrationBean;
    }
}
