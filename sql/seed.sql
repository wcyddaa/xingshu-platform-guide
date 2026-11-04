
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

/*!40000 DROP DATABASE IF EXISTS `xs-user`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `xs-user` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `xs-user`;
DROP TABLE IF EXISTS `admin_class`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_class` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(100) NOT NULL COMMENT '行政班名称',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creater_id` bigint DEFAULT NULL,
  `updater_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='行政班表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `admin_class_student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_class_student` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '行政班ID',
  `student_id` bigint NOT NULL COMMENT '学生ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creater_id` bigint DEFAULT NULL,
  `updater_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_student` (`student_id`),
  KEY `idx_class_id` (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='行政班学生关联表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `name` varchar(50) DEFAULT NULL COMMENT '姓名',
  `password` varchar(255) NOT NULL COMMENT '密码（BCrypt加密）',
  `number` varchar(20) DEFAULT NULL COMMENT '手机号/工号',
  `status` tinyint DEFAULT '1' COMMENT '状态：1正常 0禁用',
  `type` tinyint NOT NULL COMMENT '类型：1管理员 2老师 3学生',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建人ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新人ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 DROP DATABASE IF EXISTS `xs-course`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `xs-course` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `xs-course`;
DROP TABLE IF EXISTS `chapter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chapter` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `course_id` bigint NOT NULL COMMENT '所属课程ID',
  `title` varchar(200) NOT NULL COMMENT '章节标题',
  `description` varchar(1000) DEFAULT '' COMMENT '章节描述',
  `sort_order` int DEFAULT '0' COMMENT '排序序号',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  `start_page` int DEFAULT NULL COMMENT 'start_page',
  `end_page` int DEFAULT NULL COMMENT 'end_page',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_course_id` (`course_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='课程章节表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `class_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_info` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '班级ID',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '班级名称',
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '班级描述',
  `college` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '所属学院',
  `teacher_id` bigint DEFAULT NULL COMMENT '绑定教师ID',
  `teacher_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '教师姓名',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'approved' COMMENT '状态',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_name` (`name`),
  KEY `idx_name` (`name`),
  KEY `idx_teacher_id` (`teacher_id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='班级信息表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `class_student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_student` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '班级ID',
  `student_id` bigint NOT NULL COMMENT '学生ID（关联xs-user的user表，type=3）',
  `student_name` varchar(50) DEFAULT '' COMMENT '学生姓名（冗余）',
  `join_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_student` (`class_id`,`student_id`),
  KEY `idx_student_id` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='班级-学生关联表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `class_teacher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_teacher` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `class_id` bigint NOT NULL,
  `teacher_id` bigint NOT NULL,
  `teacher_name` varchar(50) DEFAULT '',
  `is_owner` tinyint DEFAULT '0',
  `join_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creater_id` bigint DEFAULT NULL,
  `updater_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_teacher` (`class_id`,`teacher_id`),
  KEY `idx_class_teacher_teacher` (`teacher_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '课程ID',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '课程名称',
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '课程描述',
  `textbook_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '教材ID（关联xs-data的教材）',
  `textbook_title` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '教材名称（冗余）',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'draft' COMMENT '课程状态：draft-草稿, pending-待审核, approved-已通过',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_textbook_id` (`textbook_id`),
  KEY `idx_creater_id` (`creater_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程信息表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `course_class`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course_class` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '关联记录ID',
  `course_id` bigint NOT NULL COMMENT '课程ID',
  `class_id` bigint NOT NULL COMMENT '班级ID',
  `class_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '班级名称（冗余）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_course_class` (`course_id`,`class_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_class_id` (`class_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程-班级关联表（多对多）';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `knowledge_edge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `knowledge_edge` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `course_id` bigint NOT NULL COMMENT '所属课程ID',
  `source_key` varchar(120) NOT NULL COMMENT '起点节点键',
  `target_key` varchar(120) NOT NULL COMMENT '终点节点键',
  `relation` varchar(50) NOT NULL DEFAULT 'contains' COMMENT '关系：contains/prerequisite/related/weak_point',
  `weight` decimal(5,2) DEFAULT '1.00' COMMENT '关系权重 0-1',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_source_key` (`source_key`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='课程知识图谱关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `knowledge_node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `knowledge_node` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `course_id` bigint NOT NULL COMMENT '所属课程ID',
  `node_key` varchar(120) NOT NULL COMMENT '节点唯一键（课程内唯一）',
  `name` varchar(200) NOT NULL COMMENT '节点名称',
  `category` varchar(30) NOT NULL DEFAULT 'concept' COMMENT '节点类型：chapter-章节, courseware-课件, question-高频提问, homework-作业易错, concept-知识点',
  `description` varchar(500) DEFAULT '' COMMENT '节点说明',
  `chapter_id` bigint DEFAULT NULL COMMENT '关联章节ID',
  `weight` decimal(5,2) DEFAULT '1.00' COMMENT '权重（证据强度 0-1）',
  `source` varchar(30) DEFAULT 'courseware' COMMENT '主要来源：courseware/question/homework/chapter',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_course_node` (`course_id`,`node_key`),
  KEY `idx_course_id` (`course_id`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='课程知识图谱节点表';
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 DROP DATABASE IF EXISTS `xs-config`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `xs-config` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `xs-config`;
DROP TABLE IF EXISTS `agent_class_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_class_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '教学班ID',
  `teacher_id` bigint NOT NULL COMMENT '配置教师ID',
  `model_config_id` bigint DEFAULT NULL COMMENT '关联模型配置ID',
  `agent_name` varchar(100) DEFAULT 'class_agent' COMMENT '智能体名称',
  `system_prompt` text COMMENT '系统提示词',
  `role_definition` varchar(500) DEFAULT '' COMMENT '角色定义',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态：active-启用, inactive-停用',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  `agent_type` varchar(50) DEFAULT 'chat',
  `base_url` varchar(500) DEFAULT '',
  `api_key` varchar(500) DEFAULT '',
  `model_name` varchar(200) DEFAULT '',
  `temperature` double DEFAULT '0.3',
  `max_tokens` int DEFAULT '4096',
  `token_limit` int DEFAULT NULL,
  `token_used` int DEFAULT '0',
  `request_limit_daily` int DEFAULT NULL,
  `request_used` int DEFAULT '0',
  `request_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_agent` (`class_id`,`agent_name`),
  KEY `idx_teacher_id` (`teacher_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='教学班智能体配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `class_quota`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_quota` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '教学班ID',
  `total_token_limit` bigint NOT NULL DEFAULT '0' COMMENT '教学班分配额度（token）',
  `token_used` bigint NOT NULL DEFAULT '0' COMMENT '教学班累计消耗 token',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_id` (`class_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='教学班智能体额度';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `model_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_type` varchar(20) NOT NULL COMMENT '配置类型：LLM-大语言模型, EMBEDDING-文本转向量',
  `agent_name` varchar(100) NOT NULL COMMENT '智能体名称（如 chat, homework）',
  `model_name` varchar(200) NOT NULL COMMENT '模型名称（如 qwen3-max, BAAI/bge-m3）',
  `base_url` varchar(500) NOT NULL COMMENT 'API地址',
  `api_key` varchar(500) NOT NULL COMMENT 'API密钥',
  `temperature` double DEFAULT '0.3' COMMENT '温度参数（仅LLM类型使用）',
  `max_tokens` int DEFAULT '4096' COMMENT '最大上下文长度',
  `test_status` varchar(20) NOT NULL DEFAULT 'untested' COMMENT '测试状态：untested-未测试, success-成功, fail-失败',
  `test_message` varchar(500) DEFAULT NULL COMMENT '最近一次测试结果说明',
  `last_test_time` datetime DEFAULT NULL COMMENT '最近一次测试时间',
  `enabled` tinyint NOT NULL DEFAULT '0' COMMENT '是否发布可用：1-已发布, 0-未发布/停用',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_agent_model` (`config_type`,`agent_name`,`model_name`),
  KEY `idx_config_type` (`config_type`),
  KEY `idx_agent_name` (`agent_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='模型配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `platform_quota`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `platform_quota` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `total_token_limit` bigint NOT NULL DEFAULT '0' COMMENT '平台总额度（token）',
  `token_used` bigint NOT NULL DEFAULT '0' COMMENT '全平台累计消耗 token',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='平台智能体总额度';
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 DROP DATABASE IF EXISTS `xs-learning`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `xs-learning` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `xs-learning`;
DROP TABLE IF EXISTS `ability_dimension`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ability_dimension` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '教学班ID',
  `chapter_id` bigint DEFAULT NULL COMMENT '章节ID（可选）',
  `dimension_name` varchar(100) NOT NULL COMMENT '能力维度名称',
  `dimension_code` varchar(50) NOT NULL COMMENT '唯一编码',
  `weight` decimal(5,2) DEFAULT '1.00' COMMENT '权重',
  `description` text COMMENT '能力描述',
  `sort_order` int DEFAULT '0' COMMENT '展示顺序',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_code` (`class_id`,`dimension_code`),
  KEY `idx_class` (`class_id`),
  KEY `idx_chapter` (`chapter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='能力维度定义表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ability_evidence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ability_evidence` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `student_id` bigint NOT NULL COMMENT '学生ID',
  `dimension_id` bigint NOT NULL COMMENT '能力维度ID',
  `source_type` enum('homework','exam','chat','quiz') NOT NULL COMMENT '证据来源类型',
  `source_id` bigint NOT NULL COMMENT '关联来源ID',
  `score` decimal(5,2) DEFAULT NULL COMMENT '本次得分',
  `evidence_text` text COMMENT '证据描述',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  KEY `idx_student_dim` (`student_id`,`dimension_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='能力证据表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_ability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_ability` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `student_id` bigint NOT NULL COMMENT '学生ID',
  `class_id` bigint NOT NULL COMMENT '教学班ID',
  `dimension_id` bigint NOT NULL COMMENT '能力维度ID',
  `mastery_level` decimal(5,2) DEFAULT '0.00' COMMENT '掌握度 0-100',
  `evidence_count` int DEFAULT '0' COMMENT '证据数量',
  `comment` text COMMENT '智能体维度评语',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_student_dimension` (`student_id`,`dimension_id`),
  KEY `idx_class` (`class_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='学生能力达成度表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_ability_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_ability_report` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `student_id` bigint NOT NULL COMMENT '学生ID',
  `class_id` bigint NOT NULL COMMENT '教学班ID',
  `overall_score` decimal(5,2) DEFAULT '0.00' COMMENT '加权综合评分 0-100',
  `summary` text COMMENT '智能体综合评语',
  `source` varchar(20) DEFAULT 'agent' COMMENT '评估来源：agent/rule',
  `question_count` int DEFAULT '0' COMMENT '参与评估的提问数',
  `homework_count` int DEFAULT '0' COMMENT '参与评估的作业数',
  `homework_avg_score` decimal(5,2) DEFAULT NULL COMMENT '作业平均分',
  `evaluated_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '评估时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_student_class` (`student_id`,`class_id`),
  KEY `idx_class` (`class_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='学生学情报告表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_question_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_question_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '教学班ID',
  `student_id` bigint NOT NULL COMMENT '学生ID',
  `student_name` varchar(100) DEFAULT '' COMMENT '学生姓名',
  `question` text COMMENT '提问内容',
  `answer` text COMMENT 'AI回答内容',
  `topics` varchar(500) DEFAULT '' COMMENT '提问主题/倾向标签',
  `tokens_used` int DEFAULT '0' COMMENT '消耗Token数',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='学生提问记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 DROP DATABASE IF EXISTS `xs-exam`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `xs-exam` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `xs-exam`;
DROP TABLE IF EXISTS `class_homework`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_homework` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `class_id` bigint NOT NULL COMMENT '班级ID',
  `class_name` varchar(100) DEFAULT '' COMMENT '班级名称（冗余）',
  `template_id` bigint NOT NULL COMMENT '模板作业ID',
  `assign_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '分配时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_template` (`class_id`,`template_id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_template_id` (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='班级作业关联表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_homework`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_homework` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `template_id` bigint NOT NULL COMMENT '模板作业ID',
  `student_id` bigint NOT NULL COMMENT '学生ID',
  `student_name` varchar(50) DEFAULT '' COMMENT '学生姓名（冗余）',
  `answer` text COMMENT '作答内容',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态：pending-待提交, submitted-已提交, graded-已批改',
  `score` double DEFAULT NULL COMMENT '分数',
  `comment` varchar(1000) DEFAULT '' COMMENT '老师评语',
  `submit_time` datetime DEFAULT NULL COMMENT '提交时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_student` (`template_id`,`student_id`),
  KEY `idx_template_id` (`template_id`),
  KEY `idx_student_id` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='学生实例作业表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `template_homework`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `template_homework` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `course_id` bigint DEFAULT NULL COMMENT '所属课程ID',
  `class_id` bigint DEFAULT NULL COMMENT '所属教学班ID',
  `chapter_id` bigint DEFAULT NULL COMMENT '关联章节ID（可选）',
  `start_page` int DEFAULT NULL COMMENT '指定教材起始页码',
  `end_page` int DEFAULT NULL COMMENT '指定教材结束页码',
  `title` varchar(200) NOT NULL COMMENT '作业标题',
  `description` text COMMENT '作业描述/内容',
  `markdown_content` mediumtext COMMENT 'Markdown格式作业文件内容',
  `attachments` mediumtext COMMENT '附件列表JSON: [{name,type,content}]',
  `teacher_id` bigint NOT NULL COMMENT '发布老师ID',
  `teacher_name` varchar(50) DEFAULT '' COMMENT '发布老师姓名',
  `status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '状态：draft-草稿, published-已发布',
  `creater_id` bigint DEFAULT NULL COMMENT '创建者ID',
  `updater_id` bigint DEFAULT NULL COMMENT '更新者ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `total_students` int DEFAULT '0' COMMENT '作业发布时教学班总人数',
  `submitted_count` int DEFAULT '0' COMMENT '已提交人数',
  `graded_count` int DEFAULT '0' COMMENT '已批改人数',
  PRIMARY KEY (`id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_chapter_id` (`chapter_id`),
  KEY `idx_teacher_id` (`teacher_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='模板作业表';
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 DROP DATABASE IF EXISTS `xs_log`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `xs_log` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `xs_log`;
DROP TABLE IF EXISTS `operation_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operation_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `operator_id` bigint NOT NULL COMMENT '操作者ID',
  `operator_name` varchar(50) DEFAULT '' COMMENT '操作者姓名',
  `operator_ip` varchar(50) DEFAULT '' COMMENT '操作IP',
  `user_agent` varchar(500) DEFAULT '' COMMENT '用户代理',
  `operation_type` varchar(50) NOT NULL COMMENT '操作类型',
  `target_type` varchar(50) NOT NULL COMMENT '目标类型',
  `target_id` varchar(200) DEFAULT '' COMMENT '目标ID',
  `target_name` varchar(200) DEFAULT '' COMMENT '目标名称',
  `status` varchar(20) NOT NULL DEFAULT 'SUCCESS' COMMENT '状态',
  `error_msg` varchar(1000) DEFAULT '' COMMENT '失败原因',
  `duration_ms` bigint DEFAULT '0' COMMENT '耗时(毫秒)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_operator_id` (`operator_id`),
  KEY `idx_operation_type` (`operation_type`),
  KEY `idx_target_type` (`target_type`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='操作日志表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;


USE `xs-user`;

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

LOCK TABLES `user` WRITE;

INSERT INTO `user` VALUES (1,'admin001','无','$2a$10$1lfr7nJvKfvg8g/4QckbhOg6gijeErAgnJdL04OK4lDrAX6R4Gs9W','13900',1,1,'2026-05-23 10:00:00','2026-07-27 10:12:26',1,1);

UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;


-- ----------------------------
-- 对象存储配置表（xs-config，平台级，仅管理员维护）
-- ----------------------------
USE `xs-config`;
CREATE TABLE IF NOT EXISTS `storage_config` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `provider` VARCHAR(20) NOT NULL DEFAULT 'agc',
    `bucket` VARCHAR(100) DEFAULT NULL,
    `region` VARCHAR(50) DEFAULT 'cn-east-3',
    `client_id` VARCHAR(100) DEFAULT NULL,
    `client_secret` VARCHAR(500) DEFAULT NULL COMMENT '加密存储',
    `status` VARCHAR(20) NOT NULL DEFAULT 'untested',
    `test_message` VARCHAR(500) DEFAULT NULL,
    `last_test_time` DATETIME DEFAULT NULL,
    `enabled` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `creater_id` BIGINT DEFAULT NULL,
    `updater_id` BIGINT DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对象存储配置表';
