server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn% %domain_idn%.HOST_DOMAIN;
    root        %docroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;
        
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;
    
    include     /etc/nginx/apps/wordpress/wordpress.conf;

    location ~ [^/]\.php(/|$) {
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        if (!-f $document_root$fastcgi_script_name) {
            return  404;
        }

        fastcgi_pass    %backend_lsnr%;
        fastcgi_index   index.php;
        include         /etc/nginx/fastcgi_params;
    }

    include     /etc/nginx/apps/wordpress/w3tc.conf;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/web/%domain%/stats/auth.conf*;
    }

    include     /etc/nginx/conf.d/common.inc;
    include     %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
