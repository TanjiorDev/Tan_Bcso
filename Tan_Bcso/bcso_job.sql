--
-- Structure de la table `criminal_records`
--

CREATE TABLE `criminal_records_bcso` (
  `depositary` varchar(40) NOT NULL,
  `name` varchar(40) NOT NULL,
  `age` varchar(10) NOT NULL,
  `height` varchar(10) NOT NULL,
  `nationality` varchar(25) NOT NULL,
  `sex` varchar(10) NOT NULL,
  `date` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Structure de la table `criminal_records_content`
--

CREATE TABLE `criminal_records_content_bcso` (
  `depositary` varchar(40) NOT NULL,
  `name` varchar(40) NOT NULL,
  `motif` varchar(200) NOT NULL,
  `date` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


ALTER TABLE `criminal_records_bcso`
  ADD PRIMARY KEY (`name`);
COMMIT;

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_bcso', 'Bcso', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_bcso', 'Bcso', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_bcso', 'Bcso', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('bcso', 'BCSO');

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('bcso',0,'recruit','Recrue',20,'{}','{}'),
	('bcso',1,'officer','Officier',40,'{}','{}'),
	('bcso',2,'sergeant','Sergent',60,'{}','{}'),
	('bcso',3,'lieutenant','Lieutenant',85,'{}','{}'),
	('bcso',4,'boss','Commandant',100,'{}','{}');




