include .env
setup:
	docker-compose build
#	docker-compose exec wordpress wp plugin install woocommerce --activate --allow-root
# docker-compose exec wordpress wp plugin install advanced-custom-fields --activate --allow-root

up:
	docker-compose up -d

reload:
	docker-compose stop
	docker-compose up -d

product-up:
	docker-compose stop
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

push-staging-all:# wp-content配下（テーマファイル、プラグイン、アップロード画像）
	docker-compose exec wordmove wordmove push -e staging -utpd
	ssh -i $(STAGING_SSH_KEY_PATH) -p $(STAGING_SSH_PORT) -l $(STAGING_SSH_USER) $(STAGING_SSH_HOST) "cd $(STAGING_DIR_PATH) && php7.4 ~/bin/wp search-replace 'http://localhost' '$(STAGING_URL)' --skip-columns=guid"

push-staging-database:
	docker-compose exec wordmove wordmove push -e staging -d
	ssh -i $(STAGING_SSH_KEY_PATH) -p $(STAGING_SSH_PORT) -l $(STAGING_SSH_USER) $(STAGING_SSH_HOST) "cd $(STAGING_DIR_PATH) && php7.4 ~/bin/wp search-replace 'http://localhost' '$(STAGING_URL)' --skip-columns=guid"

push-product: #デプロイ時に使用する想定。プラグインとテーマファイルのみ同期。
	@make product-up
	docker-compose exec wordmove wordmove push -e production -tp
	ssh -i $(PRODUCTION_SSH_KEY_PATH) -p $(PRODUCTION_SSH_PORT) -l $(PRODUCTION_SSH_USER) $(PRODUCTION_SSH_HOST) "sudo chown -R www-data:www-data $(PRODUCTION_DIR_PATH)/wp-content/themes && sudo chown -R www-data:www-data $(PRODUCTION_DIR_PATH)/wp-content/plugins" 
	@make reload

push-product-theme: #テーマのみ同期
	@make product-up
	docker-compose exec wordmove wordmove push -e production -t
	ssh -i $(PRODUCTION_SSH_KEY_PATH) -p $(PRODUCTION_SSH_PORT) -l $(PRODUCTION_SSH_USER) $(PRODUCTION_SSH_HOST) "sudo chown -R www-data:www-data $(PRODUCTION_DIR_PATH)/wp-content/themes" 
	@make reload

push-product-plugin:#プラグインのみビルド後同期
	@make product-up
	docker-compose exec wordmove wordmove push -e production -p
	ssh -i $(PRODUCTION_SSH_KEY_PATH) -p $(PRODUCTION_SSH_PORT) -l $(PRODUCTION_SSH_USER) $(PRODUCTION_SSH_HOST) "sudo chown -R www-data:www-data $(PRODUCTION_DIR_PATH)/wp-content/plugins" 
	@make reload

# push-product-all:# テーマファイル、プラグイン、アップロード画像 + DB　WP-CLIでURLの置き換え ⇒ 普段は使わない
# 	@make yarn-build
# 	docker-compose exec wordmove wordmove push -e production -utpd
# 	ssh -i $(PRODUCTION_SSH_KEY_PATH) -p $(PRODUCTION_SSH_PORT) -l $(PRODUCTION_SSH_USER) $(PRODUCTION_SSH_HOST) "chown -R www-data:www-data $(PRODUCTION_DIR_PATH)/wp-content/themes && chown -R www-data:www-data $(PRODUCTION_DIR_PATH)/wp-content/plugins" 
# 	ssh -i $(PRODUCTION_SSH_KEY_PATH) -p $(PRODUCTION_SSH_PORT) -l $(PRODUCTION_SSH_USER) $(PRODUCTION_SSH_HOST) "cd $(PRODUCTION_DIR_PATH) && wp search-replace 'http://localhost' '$(PRODUCTION_URL)' --skip-columns=guid" 
# 	@make reload


pull-product: #開発前に使用想定。DB、テーマファイル、プラグイン、アップロード画像すべてを同期します。
	@make product-up
	docker-compose exec wordmove wordmove pull -e production -utpd
	docker-compose exec wordpress wp search-replace '$(PRODUCTION_URL)' 'http://localhost' --skip-columns=guid --allow-root
	@make reload

pull-product-database: #開発前に使用想定。DBを同期します。
	@make product-up
	docker-compose exec wordmove wordmove pull -e production -d
	docker-compose exec wordpress wp search-replace '$(PRODUCTION_URL)' 'http://localhost' --skip-columns=guid --allow-root
	@make reload

pull-product-upload: #開発前に使用想定。アップロードフォルダを同期します。
	@make product-up
	docker-compose exec wordmove wordmove pull -e production -u
	@make reload

backup-product-db: #DBダンプ。一応push時には毎回dbダンプされるようにしています。
	ssh -i $(PRODUCTION_SSH_KEY_PATH) -p $(PRODUCTION_SSH_PORT) -l $(PRODUCTION_SSH_USER) $(PRODUCTION_SSH_HOST) "mysqldump $(PRODUCTION_DB_NAME) --host=$(PRODUCTION_DB_HOST) --port=$(PRODUCTION_DB_PORT) --user=$(PRODUCTION_DB_USER) --password=$(PRODUCTION_DB_PASSWORD) --result-file=/tmp/dump`date "+%Y%m%d_%H%M%S"`.sql --no-tablespaces"