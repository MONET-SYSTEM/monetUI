create database monetdb;

use monetdb;

CREATE TABLE `users` (
  `uuid` CHAR(36) NOT NULL,
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `email_verified_at` TIMESTAMP NULL DEFAULT NULL,
  `password` VARCHAR(255) NOT NULL,
  `remember_token` VARCHAR(100) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`uuid`),
  UNIQUE KEY `id_unique` (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO users (uuid, name, email, email_verified_at, password, remember_token, created_at, updated_at)
VALUES 
  (UUID(), 'Marjovic Alejado', 'marjovic.alejado@gmail1.com', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa2yIK1yyRq1C5y/f7Kwy5Is4G6', 'token1', NOW(), NOW()),
  (UUID(), 'Aslainie Maruhom', 'aslainie.maruhom@gmail1.com', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa2yIK1yyRq1C5y/f7Kwy5Is4G6', 'token2', NOW(), NOW()),
  (UUID(), 'Gerald Michael Ablitado', 'gerald.michael.ablitado@gmail1.com', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa2yIK1yyRq1C5y/f7Kwy5Is4G6', 'token3', NOW(), NOW()),
  (UUID(), 'Dainty Deanne Lamberto', 'dainty.deanne.lamberto@gmail1.com', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa2yIK1yyRq1C5y/f7Kwy5Is4G6', 'token4', NOW(), NOW());

CREATE TABLE `otps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `code` VARCHAR(255) NOT NULL,
  `type` VARCHAR(255) NOT NULL,
  `active` INT NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `otps_user_id_foreign` (`user_id`),
  CONSTRAINT `otps_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `personal_access_tokens` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tokenable_id` BIGINT UNSIGNED NOT NULL,
  `tokenable_type` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `abilities` TEXT DEFAULT NULL,
  `last_used_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_index` (`tokenable_id`, `tokenable_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
