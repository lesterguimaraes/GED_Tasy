-- MySQL dump 10.13  Distrib 5.7.44, for Linux (x86_64)
--
-- Host: localhost    Database: ged
-- ------------------------------------------------------
-- Server version	5.7.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `documentos`
--

DROP TABLE IF EXISTS `documentos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `documentos` (
  `id_documento` int(11) NOT NULL AUTO_INCREMENT,
  `id_grupo_documento` int(11) NOT NULL,
  `nome_arquivo` varchar(255) NOT NULL,
  `caminho_arquivo` varchar(512) NOT NULL,
  `dt_upload` datetime DEFAULT CURRENT_TIMESTAMP,
  `cd_pessoa_fisica` int(11) NOT NULL,
  `login` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id_documento`),
  KEY `id_grupo_documento` (`id_grupo_documento`),
  CONSTRAINT `documentos_ibfk_1` FOREIGN KEY (`id_grupo_documento`) REFERENCES `grupo_pasta` (`id_grupo_documento`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documentos`
--

LOCK TABLES `documentos` WRITE;
/*!40000 ALTER TABLE `documentos` DISABLE KEYS */;
INSERT INTO `documentos` VALUES (7,2,'entregas_legais_fev2025.pdf','static/uploads/75502/2/entregas_legais_fev2025.pdf','2025-06-10 12:08:37',75502,'lester'),(8,1,'fleg_Baixa_saldo_disponivel_esta_marcada.pdf','static/uploads/75502/1/fleg_Baixa_saldo_disponivel_esta_marcada.pdf','2025-06-10 12:22:31',75502,'lester'),(9,1,'Lote_medicamentos_SN_Aprazados.pdf','static/uploads/70095/1/Lote_medicamentos_SN_Aprazados.pdf','2025-06-11 13:47:54',70095,'lester');
/*!40000 ALTER TABLE `documentos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `empresas`
--

DROP TABLE IF EXISTS `empresas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `empresas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `descricao` text,
  `status` char(1) DEFAULT 'A',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `empresas`
--

LOCK TABLES `empresas` WRITE;
/*!40000 ALTER TABLE `empresas` DISABLE KEYS */;
INSERT INTO `empresas` VALUES (1,'Hospital Beira Mar','HBM - Registro via banco','A');
/*!40000 ALTER TABLE `empresas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grupo_pasta`
--

DROP TABLE IF EXISTS `grupo_pasta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `grupo_pasta` (
  `id_grupo_documento` int(11) NOT NULL AUTO_INCREMENT,
  `ds_grupo_documento` varchar(255) NOT NULL,
  `grupo_pai_id` int(11) DEFAULT NULL,
  `id_usuario_cadastro` int(11) DEFAULT NULL,
  `dt_cadastro` datetime DEFAULT CURRENT_TIMESTAMP,
  `dt_atualizacao` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `status` char(1) DEFAULT 'A',
  `login` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id_grupo_documento`),
  KEY `grupo_pai_id` (`grupo_pai_id`),
  CONSTRAINT `grupo_pasta_ibfk_1` FOREIGN KEY (`grupo_pai_id`) REFERENCES `grupo_pasta` (`id_grupo_documento`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grupo_pasta`
--

LOCK TABLES `grupo_pasta` WRITE;
/*!40000 ALTER TABLE `grupo_pasta` DISABLE KEYS */;
INSERT INTO `grupo_pasta` VALUES (1,'Documento de Identificação (RG | CNH)',NULL,2,'2025-06-03 12:17:55','2025-06-03 12:17:55','A',NULL),(2,'CPF',1,2,'2025-06-03 12:18:02','2025-06-03 12:18:02','A',NULL),(3,'Exames de Imagem',NULL,2,'2025-06-03 12:18:16','2025-06-04 08:28:48','A',NULL),(4,'Ressonância Magnética',3,2,'2025-06-03 12:18:22','2025-06-03 12:18:22','A',NULL),(5,'Carteira do Plano de Saúde',1,2,'2025-06-03 12:18:39','2025-06-03 12:18:39','A',NULL),(6,'Raio-X',3,2,'2025-06-03 12:18:45','2025-06-03 12:18:45','A',NULL),(7,'Exames Laboratoriais',NULL,2,'2025-06-03 19:41:50','2025-06-04 08:28:48','A','admin'),(8,'Tomografia',3,1,'2025-06-04 08:21:50','2025-06-04 08:21:50','A','lester'),(9,'Termo de Consentimento',NULL,1,'2025-06-04 08:30:27','2025-06-04 08:30:27','A','lester');
/*!40000 ALTER TABLE `grupo_pasta` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `log_acesso`
--

DROP TABLE IF EXISTS `log_acesso`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_acesso` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(100) NOT NULL,
  `tipo_acesso` enum('V','F') NOT NULL COMMENT 'V = VÃ¡lido, F = Falha',
  `data_hora` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `login` (`login`),
  KEY `data_hora` (`data_hora`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `log_acesso`
--

LOCK TABLES `log_acesso` WRITE;
/*!40000 ALTER TABLE `log_acesso` DISABLE KEYS */;
INSERT INTO `log_acesso` VALUES (1,'admin','V','2025-06-03 12:17:36'),(2,'admin','V','2025-06-03 14:47:55'),(3,'admin','V','2025-06-03 17:32:46'),(4,'admin','V','2025-06-03 19:29:49'),(5,'lester','V','2025-06-04 08:09:49'),(6,'admin','V','2025-06-04 09:36:45'),(7,'lester','V','2025-06-04 11:20:16'),(8,'lester','V','2025-06-04 13:06:25'),(9,'lester','V','2025-06-04 14:02:30'),(10,'lester','V','2025-06-04 14:19:50'),(11,'lester','V','2025-06-04 20:33:37'),(12,'lester','V','2025-06-04 20:45:47'),(13,'lester','V','2025-06-04 20:55:56'),(14,'lester','V','2025-06-04 20:59:22'),(15,'lester','V','2025-06-04 21:00:02'),(16,'lester','V','2025-06-04 21:03:29'),(17,'lester','V','2025-06-05 08:10:53'),(18,'lester','V','2025-06-05 08:11:46'),(19,'lester','F','2025-06-05 08:41:40'),(20,'lester','V','2025-06-05 08:41:45'),(21,'lester','F','2025-06-05 08:44:31'),(22,'lester','V','2025-06-05 08:44:38'),(23,'lester','V','2025-06-05 09:30:29'),(24,'lester','V','2025-06-07 08:50:21'),(25,'lester','V','2025-06-07 11:18:19'),(26,'lester','V','2025-06-07 11:50:41'),(27,'lester','V','2025-06-07 13:45:42'),(28,'lester','V','2025-06-07 14:42:10'),(29,'lester','V','2025-06-09 10:31:08'),(30,'lester','V','2025-06-09 11:21:02'),(31,'lester','V','2025-06-10 12:07:22'),(32,'lester','V','2025-06-11 09:34:53'),(33,'lester','V','2025-06-11 09:59:49'),(34,'lester','V','2025-06-11 10:01:13'),(35,'lester','V','2025-06-11 13:46:35'),(36,'lester','V','2025-06-12 08:00:22'),(37,'lester','V','2025-06-12 08:21:13'),(38,'lester','V','2025-06-12 08:30:45'),(39,'lester','V','2025-06-23 09:49:20'),(40,'lester','V','2025-06-30 11:57:37'),(41,'lester','V','2025-07-01 21:33:18'),(42,'lester','V','2025-07-02 08:09:59'),(43,'lester','V','2025-07-02 13:55:25');
/*!40000 ALTER TABLE `log_acesso` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pessoa_fisica`
--

DROP TABLE IF EXISTS `pessoa_fisica`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pessoa_fisica` (
  `id_pessoa_fisica` int(11) NOT NULL AUTO_INCREMENT,
  `cd_pessoa_fisica` int(11) DEFAULT NULL,
  `nome_pessoa_fisica` varchar(255) DEFAULT NULL,
  `nr_prontuario` varchar(50) DEFAULT NULL,
  `cd_pessoa_fisica_anterior` int(11) DEFAULT NULL,
  `nr_prontuario_alterior` varchar(50) DEFAULT NULL,
  `dt_criacao` datetime DEFAULT CURRENT_TIMESTAMP,
  `dt_atualizacao` datetime DEFAULT NULL,
  `login` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id_pessoa_fisica`),
  UNIQUE KEY `cd_pessoa_fisica` (`cd_pessoa_fisica`)
) ENGINE=InnoDB AUTO_INCREMENT=98 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pessoa_fisica`
--

LOCK TABLES `pessoa_fisica` WRITE;
/*!40000 ALTER TABLE `pessoa_fisica` DISABLE KEYS */;
INSERT INTO `pessoa_fisica` VALUES (1,70095,'Lester Gomes Guimaraes','46424',70099,NULL,NULL,'2025-06-04 12:02:41',NULL),(2,72021,'Leandro Bueno','',NULL,NULL,NULL,NULL,NULL),(3,75379,'Davi Garcia Pereira','46952',NULL,NULL,'2025-06-03 18:23:26',NULL,NULL),(7,37446,'Claudinei David Manoel','25598',NULL,NULL,'2025-06-03 19:14:27',NULL,NULL),(10,73495,'Renata Maria Barcelos Sens','46953',NULL,NULL,'2025-06-03 19:32:36',NULL,'admin'),(11,70094,'Paulo Cesar Martins','45169',NULL,NULL,'2025-06-04 11:45:21',NULL,'lester'),(12,70114,'Fernanda Francisco da Silva ','45029',NULL,NULL,'2025-06-04 14:06:58',NULL,'lester'),(13,75340,'Claure Inez Corso Baggio','46964',NULL,NULL,'2025-06-07 09:04:43',NULL,'job'),(14,28438,'Amanda Pesarini','46963',NULL,NULL,'2025-06-07 09:04:43',NULL,'job'),(15,75501,'Francheska Luzia da Silva','46962',NULL,NULL,'2025-06-07 09:04:43',NULL,'job'),(16,75465,'Wilma Simone de Fatima Varotto','46960',NULL,NULL,'2025-06-07 09:04:43',NULL,'job'),(21,75470,'Suzana Bonadiman','46968',NULL,NULL,'2025-06-09 11:03:02',NULL,'job'),(22,75510,'Kamila Nandi de Souza','46967',NULL,NULL,'2025-06-09 11:03:02',NULL,'job'),(23,75217,'Aline da Silva','46965',NULL,NULL,'2025-06-09 11:03:02',NULL,'job'),(24,72386,'Samuara Rodrigues de Rodrigues ','45954',NULL,NULL,'2025-06-09 11:03:02',NULL,'job'),(25,75537,'Ines Pires dos Santos','46969',NULL,NULL,'2025-06-10 03:00:02',NULL,'job'),(26,74040,'Juliana da Rocha Roncaratti','46972',NULL,NULL,'2025-06-10 12:08:03',NULL,'job'),(27,75434,'Evandro Bortoletto Vazquez Varela','46970',NULL,NULL,'2025-06-10 12:08:03',NULL,'job'),(28,75538,'Elisandra da Silva Bugmann','46973',NULL,NULL,'2025-06-10 12:08:03',NULL,'job'),(29,75327,'Aurea Isabel Rodrigues Ferreira','46974',NULL,NULL,'2025-06-10 12:08:03',NULL,'job'),(30,75502,'Olindina Machado Rubik','46971',NULL,NULL,'2025-06-10 12:08:03',NULL,'job'),(31,75514,'Vilmo Nivaldo dos Santos','46975',NULL,NULL,'2025-06-11 03:00:02',NULL,'job'),(32,75454,'Maria Lapa Bernardes Martins','46981',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(33,75319,'Gloria Eiko Araki','46982',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(34,75453,'Simone de Souza','46979',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(35,75237,'Viviane Poyastro Pinheiro','46977',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(36,75333,'Dilair Salete Daroit','46922',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(37,75179,'Paulina Elza da Silva Trierweiller','46980',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(38,75521,'Juliana Iete Nunes','46984',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(39,75451,'Anaelise Wenceslau Trindade','46983',NULL,NULL,'2025-06-13 03:00:02',NULL,'job'),(40,70657,'Cassiane Lima Ferreira ','45898',NULL,NULL,'2025-06-14 03:00:02',NULL,'job'),(41,70630,'Marlene Maria Machado de Andrade','45366',NULL,NULL,'2025-06-14 03:00:02',NULL,'job'),(42,75542,'Andrea Cerboni Wissing','46986',NULL,NULL,'2025-06-14 03:00:02',NULL,'job'),(43,69173,'Maria Cristina Soccol Pasquali','46989',NULL,NULL,'2025-06-14 03:00:02',NULL,'job'),(44,75543,'Nirlei Fatima Binda Lucion','46991',NULL,NULL,'2025-06-14 03:00:02',NULL,'job'),(45,75565,'Marcia Regina Spezia','46990',NULL,NULL,'2025-06-14 03:00:02',NULL,'job'),(46,74826,'Talita Samuel Bacchi','46809',NULL,NULL,'2025-06-15 03:00:02',NULL,'job'),(47,75544,'Riani Garcia Vargas Tezza','46994',NULL,NULL,'2025-06-15 03:00:02',NULL,'job'),(48,75485,'Deise Carina Homiak Teston','46992',NULL,NULL,'2025-06-15 03:00:02',NULL,'job'),(49,75486,'Paulo Sergio Teston','46993',NULL,NULL,'2025-06-15 03:00:02',NULL,'job'),(50,75545,'Bruna Prado da Silva','46995',NULL,NULL,'2025-06-16 03:00:03',NULL,'job'),(51,75547,'Emilly Taruhn de Souza','47001',NULL,NULL,'2025-06-17 03:00:02',NULL,'job'),(52,75576,'Morgana Tonon Pacifico','46998',NULL,NULL,'2025-06-17 03:00:02',NULL,'job'),(53,75548,'Vanessa Krummenauer','47002',NULL,NULL,'2025-06-17 03:00:02',NULL,'job'),(54,75479,'Eduardo Jose Rutkosky','47003',NULL,NULL,'2025-06-18 03:00:02',NULL,'job'),(55,75573,'Hellen Assuncao da Silva','47007',NULL,NULL,'2025-06-18 03:00:02',NULL,'job'),(56,75586,'Vilma Petri Ventura','47012',NULL,NULL,'2025-06-19 03:00:02',NULL,'job'),(57,75633,'Suelli Maria da Silva','47011',NULL,NULL,'2025-06-19 03:00:02',NULL,'job'),(58,75622,'Volmir Leidens','47015',NULL,NULL,'2025-06-20 03:00:02',NULL,'job'),(59,75624,'Lais Joice Senger Luy','47014',NULL,NULL,'2025-06-20 03:00:02',NULL,'job'),(60,75621,'Elisabete Hoegen','47013',NULL,NULL,'2025-06-20 03:00:02',NULL,'job'),(61,72301,'Fatima Eliane Samuel','45932',NULL,NULL,'2025-06-21 03:00:03',NULL,'job'),(62,75648,'Denise Sarturi','47016',NULL,NULL,'2025-06-21 03:00:03',NULL,'job'),(63,75626,'Giselle Borgognon De Casco','47017',NULL,NULL,'2025-06-21 03:00:03',NULL,'job'),(64,75629,'Ada Poliana Moreira Nagem','47018',NULL,NULL,'2025-06-21 03:00:03',NULL,'job'),(65,75413,'Robson Costa','47022',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(66,75113,'Juliane Pellanda','47025',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(67,75631,'Nathalia Siqueira Julio','47020',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(68,75630,'Adila Arruda Safi','47019',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(69,75650,'Marines de Oliveira','47021',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(70,75651,'Andreza Miria Bento Peixoto','47023',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(71,75652,'Marcia Andreia Cunha de Oliveira','47024',NULL,NULL,'2025-06-22 03:00:02',NULL,'job'),(72,75660,'Giovanna Cristina Campos Jube Barbosa','47029',NULL,NULL,'2025-06-24 03:00:03',NULL,'job'),(73,75663,'Thais Meime Santos','47026',NULL,NULL,'2025-06-24 03:00:03',NULL,'job'),(74,75678,'Ana Katia Monteiro Rodrigues Gomes','47030',NULL,NULL,'2025-06-24 03:00:03',NULL,'job'),(75,72446,'Chaiany da Guia Licariao Costa','47032',NULL,NULL,'2025-06-25 03:00:02',NULL,'job'),(76,67178,'Licinia Maria Ungarelli Toledo','42976',NULL,NULL,'2025-06-25 03:00:02',NULL,'job'),(77,75661,'Fernanda Diamantina de Oliveira Grellet','47038',NULL,NULL,'2025-06-26 03:00:03',NULL,'job'),(78,56301,'Fernanda Maciel Witiuk','35249',NULL,NULL,'2025-06-26 03:00:03',NULL,'job'),(79,75643,'Edna Pereira Rodrigues','47039',NULL,NULL,'2025-06-26 03:00:03',NULL,'job'),(80,75666,'Liziane Regina Tonial','47037',NULL,NULL,'2025-06-26 03:00:03',NULL,'job'),(81,75665,'Ana Maria do Prado','47034',NULL,NULL,'2025-06-26 03:00:03',NULL,'job'),(82,75639,'Natalia da Rosa Cichoski Henrique','47040',NULL,NULL,'2025-06-26 03:00:03',NULL,'job'),(83,75387,'Aline Sanceverino da Silva','47041',NULL,NULL,'2025-06-27 03:00:03',NULL,'job'),(84,75720,'Graziela Duarte Tasca','47051',NULL,NULL,'2025-07-01 03:00:04',NULL,'job'),(85,75719,'Ramon da Rosa Correa','47047',NULL,NULL,'2025-07-01 03:00:04',NULL,'job'),(86,75687,'Vania D\'aquino Pinho','47048',NULL,NULL,'2025-07-01 03:00:04',NULL,'job'),(87,63198,'Fabiana da Silveira','40171',NULL,NULL,'2025-07-01 03:00:04',NULL,'job'),(88,75689,'Vivian Cristina Zilli','47052',NULL,NULL,'2025-07-01 03:00:04',NULL,'job'),(89,74045,'Vitoria de Almeida Crippa','47054',NULL,NULL,'2025-07-02 03:00:03',NULL,'job'),(90,75735,'Eduardo D Avila da Cunha','47055',NULL,NULL,'2025-07-02 03:00:03',NULL,'job'),(91,75793,'Fernanda Figueira Serafim','47058',NULL,NULL,'2025-07-03 03:00:03',NULL,'job'),(92,75772,'Daniela Leomara Pacheco da Silva','47063',NULL,NULL,'2025-07-05 03:00:03',NULL,'job'),(93,75588,'Nicolly Reitz da Luz Venancio','47064',NULL,NULL,'2025-07-06 03:00:03',NULL,'job'),(94,75773,'Julia Wippel da Cunha Pereira','47065',NULL,NULL,'2025-07-06 03:00:03',NULL,'job'),(95,75589,'Gabryelle Ferreira Cabral','47066',NULL,NULL,'2025-07-06 03:00:03',NULL,'job'),(96,75590,'Ana Clara de Castro Araujo','47067',NULL,NULL,'2025-07-06 03:00:03',NULL,'job'),(97,71590,'Maria Adelaide de Holanda Lima ','45709',NULL,NULL,'2025-07-06 03:00:03',NULL,'job');
/*!40000 ALTER TABLE `pessoa_fisica` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(50) NOT NULL,
  `nome` varchar(250) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `senha` varchar(255) NOT NULL,
  `status` char(1) NOT NULL,
  `tipo` varchar(20) NOT NULL DEFAULT 'Editor',
  `empresa_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `login` (`login`),
  KEY `fk_empresa_id` (`empresa_id`),
  CONSTRAINT `fk_usuarios_empresa` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'lester','Administrador',NULL,'scrypt:32768:8:1$Ja08ODNOQ6LGIxPB$50ebd84e242b5c1b5f7ec672220f0074bd01081bb10f27a93728359188dcee97d0b96d0fac4e40eb65838549ea0652ee988ed185c5d96e28462165c8bdba38e1','A','Administrador',NULL),(2,'admin','Administrador',NULL,'scrypt:32768:8:1$JSOMnMN7GB7uHize$ad651820676e2bdfdf946427c3a641e7e66ccc221b3b854cba797d8e683f363ea06e7430ca3ce50a4c41ad506cf6e760a16271c4585a586ed33b07f562a65dcd','I','Administrador',NULL);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-07-08  2:00:03
