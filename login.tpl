{* Split-screen auth shell — brand panel + form card. Full-width,
   edge-to-edge; header.tpl gives .main-content a plain col-xs-12 on
   this page specifically so there is no Bootstrap column fighting
   this layout for width. Styling: hostorio-layout.css, "AUTH PAGES". *}
<div class="ho-auth">

    <div class="ho-auth-panel">
        <div class="ho-auth-panel-inner">
            <a href="{$WEB_ROOT}/index.php" class="ho-auth-logo">
                <img src="{$WEB_ROOT}/assets/img/hostorio-com-logo.png" alt="{$companyname}">
            </a>
            <div class="ho-auth-panel-tag">Client Portal</div>
            <h2 class="ho-auth-panel-title">Manage your <span>hosting &amp; domains</span> with ease</h2>
            <p class="ho-auth-panel-desc">A complete client portal to manage domains, invoices, services and support — all in one place.</p>
            {include file="$template/includes/ho-auth-features.tpl"}
        </div>
    </div>

    <div class="ho-auth-form-side">
        <div class="ho-auth-card{if $linkableProviders} ho-auth-card-wide{/if}">
            <h1 class="ho-auth-card-title">{$LANG.login}</h1>
            <p class="ho-auth-card-subtitle">Sign in to your account to continue</p>

            {include file="$template/includes/flashmessage.tpl"}
            <div class="providerLinkingFeedback"></div>

            {if $remote_auth_prelinked}
            <div class="alert alert-warning" role="alert">
                <i class="fas fa-exclamation-triangle"></i>
                {lang key='remoteAuthn.oneTimeAuthRequired'}
            </div>
            {/if}

            <div class="row">
                <div class="col-sm-{if $linkableProviders}7{else}12{/if}">

                    <form method="post" action="{routePath('login-validate')}" class="login-form ho-auth-form" role="form">
                        <div class="form-group">
                            <label for="inputEmail">{$LANG.clientareaemail}</label>
                            <input type="email" name="username" class="form-control" id="inputEmail" placeholder="{$LANG.enteremail}" autofocus>
                        </div>

                        <div class="form-group">
                            <label for="inputPassword">{$LANG.clientareapassword}</label>
                            <input type="password" name="password" class="form-control" id="inputPassword" placeholder="{$LANG.clientareapassword}" autocomplete="off" >
                        </div>

                        <div class="ho-auth-form-row">
                            <label class="ho-auth-remember">
                                <input type="checkbox" name="rememberme" /> {$LANG.loginrememberme}
                            </label>
                            <a href="{routePath('password-reset-begin')}" class="ho-auth-forgot">{$LANG.forgotpw}</a>
                        </div>

                        {if $captcha->isEnabled()}
                            <div class="text-center margin-bottom">
                                {include file="$template/includes/captcha.tpl"}
                            </div>
                        {/if}

                        <button id="login" type="submit" class="ho-auth-submit{$captcha->getButtonClass($captchaForm)}">{$LANG.loginbutton}</button>
                    </form>

                </div>
                <div class="col-sm-5{if !$linkableProviders} hidden{/if}">
                    {include file="$template/includes/linkedaccounts.tpl" linkContext="login" customFeedback=true}
                </div>
            </div>

            <p class="ho-auth-switch">Don't have an account? <a href="{$WEB_ROOT}/register.php">Create one</a></p>
        </div>
    </div>

</div>
