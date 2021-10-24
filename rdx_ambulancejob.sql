USE `redm_extended`;

INSERT INTO `addon_account` (name, label, shared) VALUES
  ('society_ambulance', 'Medico', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
  ('society_ambulance', 'Medico', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
  ('society_ambulance', 'Medico', 1)
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  ('ambulance',0,'ambulance','Curandeiro',3,'{}'),
  ('ambulance',1,'doctor','Medeco',4,'{}'),
  ('ambulance',2,'chief_doctor','Medeco-chefe',6,'{}'),
  ('ambulance',3,'boss','Boss',8,'{}')
;

INSERT INTO `jobs` (name, label) VALUES
  ('ambulance','Medico')
;

INSERT INTO `items` (name, label, weight) VALUES
  ('bandage','Bandage', 20),
  ('medikit','Medikit', 5)
;
INSERT INTO `items` (`name`, `label`, `weight`) VALUES
	('bandage', 'Ligadura', 5),
	('medikit','Kit-Medico', 15)
;

ALTER TABLE `users` ADD `isDead` BIT(1) DEFAULT b'0'