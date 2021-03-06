/* Ensure clean Database Schema 
 * Run this before running any of the other init_scripts
 */
drop schema if exists public CASCADE; 
create schema public; 

/*
 * A USER can be an OWNER or a CARETAKER
 * (i.e Covering Constraint and Overlapping Constraint satisfied)
 */
create table USERS (
	user_id 	bigserial primary key,
	name 		text not null,
	email 		text unique not null,
	phone 		varchar(20) unique not null,
	address 	json not null,
	password	char(60) not null,
	created 	timestamp not null default NOW()
);

-- <Sends> collapsed into it
-- status: 0=unattended, 1=attending, 2=solved
create table REQUESTS (
	request_id 		bigserial primary key,
	message 		text not null,
	status 			integer not null default 0 check (status>-1 and status<3),
	created 		timestamp not null default NOW(), 
	user_id 		bigserial not null,
	foreign key (user_id) references USERS
);

create table MANAGERS (
	manager_id 	bigserial primary key,
	email 		text unique not null,
	username 	text not null,
	password	char(60) not null,
	phone 		varchar(20) unique not null
);

create table Handles (
	manager_id 	bigserial,
	request_id 	bigserial,
	assigned	timestamp default NOW(),
	justification	text,	--by manager
	primary key (manager_id, request_id),
	foreign key (manager_id) references MANAGERS,
	foreign key (request_id) references REQUESTS
);

create table OWNERS (
	user_id 	bigserial primary key,
	foreign key (user_id) references USERS
);

create table ANIMALS (
	type text primary key 
);

-- <isOfType> collapsed into this
create table PETS (
	pet_id 		bigserial primary key,
	name 		text not null, 
	type 		text not null, 
	biography 	text,
	born 		date not null, 
	death		date, 
	foreign key (type) references ANIMALS
);

-- Design consideration. Till and Owns here (instead of Pets as weak entity) because 
-- we want the application to be able to handle pet transfers later on without losing information on the 
-- pet. Logistics of it has to be solved later, and is beyond the scope of the module. 
create table Owns (
	pet_id 		bigserial,
	owner_id 	bigserial,
	since 		date not null,
	till 		date,
	primary key (pet_id, owner_id),
	foreign key (pet_id) references PETS,
	foreign key (owner_id) references OWNERS(user_id)
);

create table CARETAKERS (
	user_id 	bigserial primary key,
	rating 		float4 not null default 0,
	foreign key (user_id) references USERS
);

create table Likes (
	caretaker_id 	bigserial, 
	type 			text, 
	primary key 	(caretaker_id, type), 
	foreign key (caretaker_id) references caretakers (user_id),
	foreign key (type) references ANIMALS
);

-- <Offers> collapsed into this
-- status: 0=retracted, 1=available, 2=taken
create table SERVICES (
	service_id		bigserial primary key,
	caretaker_id 	bigserial not null,
	starting 		timestamp not null,
	ending 			timestamp not null check (ending > starting),
	status 			integer not null default 1 check (status>-1 and status<3), 
	minWage			integer not null check (minWage > 0),
	foreign key (caretaker_id) references CARETAKERS
);

-- <Places> Collapsed into this
-- status: 0=rejected, 1=pending, 2=success 
create table BIDS (
	bid_id		bigserial primary key,
	money 		integer check (money>0),
	status 		integer not null default 1 check (status>-1 and status<3), 
	starting 	timestamp not null, 
	ending 		timestamp not null check (ending > starting), 
	owner_id 	bigserial not null,
	pet_id 		bigserial not null,
	service_id 	bigserial not null,
	foreign key (pet_id) references Pets,
	foreign key (owner_id) references Owners,
	foreign key (service_id) references SERVICES
);

-- <Creates> collapsed into this
-- status: 1=upcoming, 2=finished
create table TASKS (
	task_id 		bigserial primary key,
	bid_id 			bigserial not null unique,
	status 			integer not null default 1 check (status=1 or status=2),
	foreign key (bid_id) references BIDS
);

-- <Gives>, <Receives>, <Has> collapsed into this
create table REVIEWS (
	reviewNum		integer,	--increment with trigger?
	note 			text,
	stars 			integer not null check (stars>=0 and stars<=5),
	task_id			bigserial unique not null,
	caretaker_id 	bigserial,
	owner_id 		bigserial not null,
	foreign key (task_id) references TASKS,
	foreign key (caretaker_id) references CARETAKERS,
	foreign key (owner_id) references OWNERS,
	primary key (caretaker_id, reviewNum)
);

-- Init data
insert into animals (type) values ('Cat'); 
insert into animals (type) values ('Dog'); 
insert into animals (type) values ('Snake'); 

INSERT INTO users (name, email, phone, address, password) VALUES ('saifum', 'saifum@u.nus.edu', '123456', '{"address": "pgph"}', '$2b$10$Ylwc8mZnLwD8RbZSYr3kx.6nmIHocDE4ZoH2kFwEx9BkhSW8Ucwqy') RETURNING *;
insert into caretakers (user_id) values (1);
insert into likes (caretaker_id, type) values (1, 'Cat'); 
insert into likes (caretaker_id, type) values (1, 'Dog'); 
INSERT INTO users (name, email, phone, address, password) VALUES ('jj', 'jj@u.nus.edu', '123457', '{"address": "ke7"}', '$2b$10$Ylwc8mZnLwD8RbZSYr3kx.6nmIHocDE4ZoH2kFwEx9BkhSW8Ucwqy') RETURNING *;
insert into owners (user_id) values (2); 
insert into managers (email, username, password, phone) values ('manager@u.nus.edu', 'manager', '$2b$10$Ylwc8mZnLwD8RbZSYr3kx.6nmIHocDE4ZoH2kFwEx9BkhSW8Ucwqy', '123458'); 

INSERT INTO pets (name, type, biography, born) VALUES ('Tom','Cat', 'Tom is a cat.', '2016-06-23');
INSERT INTO owns (pet_id, owner_id, since) VALUES (1, 2, '2016-06-23');

-- a Task Creation Flow
INSERT INTO services (caretaker_id, starting, ending, minWage, status) VALUES (1, '2019-04-01 20:00:00', '2019-04-01 21:00:00', 50, 2);
insert into bids (starting, ending, money, owner_id, pet_id, service_id, status) values ('2019-04-01 20:28:32', '2019-04-03 20:28:33', 60, 2, 1, 1, 2); 
insert into TASKS (bid_id) values (1); 
INSERT INTO services (caretaker_id, starting, ending, minWage, status) VALUES (1, '2019-04-02 20:00:00', '2019-04-02 21:00:00', 50, 2);
insert into bids (starting, ending, money, owner_id, pet_id, service_id, status) values ('2019-04-02 20:28:32', '2019-04-02 20:28:33', 60, 2, 1, 2, 2); 
insert into TASKS (bid_id) values (2); 

------TRIGGERS------------
-- Trigger 1
create or replace function removeService() returns trigger as $$ 
declare isTask integer; 
begin
	-- can't remove if Task exists (i.e a successful bid exists)
	select count(*) into isTask from Bids B where B.service_id=new.service_id and status=2; 
	if isTask > 0 then raise notice 'Cannot remove as task exists.'; return null;  
	else return new; end if; 
end; $$ language plpgsql; 

create trigger removingService
before update on services
for each row
execute procedure removeService(); 

-- Trigger 2
create or replace function placeBid()
returns trigger as $$ 
declare earliest timestamp; 
		latest timestamp; 
		preferences text[]; 
		likesType text; 
		petType text; 
		compatibility boolean;  
begin
	select starting, ending into earliest, latest from services where service_id=new.service_id;
	select likes into preferences from caretakers natural join services where service_id=new.service_id limit 1; 
	select type into petType from pets where pet_id=new.pet_id;  	
	compatibility:= false; 
	-- ToDO petTypeCompatibility @Psyf 

	if new.starting < earliest then raise notice 'Starts later.'; return null; 
	elseif new.ending > latest then raise notice 'Ends earlier.'; return null; 
	-- elseif compatibility=false then raise notice 'Not in pet preference.'; return null; 
	elseif (select status from services where service_id=new.service_id)=2 then raise notice 'Bidding closed.'; return null; 
	else return new; end if; 
end; $$ language plpgsql; 

create trigger placingBid
before insert on Bids 
for each row
execute procedure placeBid(); 

-- Trigger 3
create or replace function offerService() 
returns trigger as $$ 
declare oldStart timestamp; oldEnd timestamp; 
begin
	for oldStart, oldEnd in select starting, ending from services where caretaker_id=new.caretaker_id and status<>0
	loop
		if new.starting >= oldStart and new.starting <= oldEnd then raise notice 'Taken/Available service exists with time overlap.'; return null; 
		elseif new.ending >= oldStart and new.ending <= oldEnd then raise notice 'Taken/Available service exists with time overlap.'; return null;
		elseif new.starting <= oldStart and new.ending >= oldEnd then raise notice 'Taken/Available service exists with time overlap.'; return null;
		else return new; 
		end if; 
	end loop; 
end; $$ language plpgsql; 

create trigger offeringService 
before insert on services
for each row
execute procedure offerService(); 

-- Trigger 4
create or replace function sendReview() 
returns trigger as $$ 
declare lastNum integer; endTime timestamp; 
begin 
	select coalesce(max(reviewnum), 0) into lastNum from reviews where caretaker_id=new.caretaker_id; 
	select ending into endTime from tasks natural join bids where task_id=new.task_id; 
	
	if endTime > NOW() then raise notice 'Wait till the task is over to send review.'; return null; 
	else new.reviewnum = lastNum+1; return new; 
	end if;
		
	-- TODO @ Psyf defensive coding by making sure owner and caretaker actually related to num. 
end; $$ language plpgsql;

create trigger sendingReview
before insert on Reviews 
for each row 
execute procedure sendReview(); 

-- Trigger 5
create or replace function deleteTask()
returns trigger as $$ begin 
	if old.status=2 then raise notice 'Cant delete as task is finished.'; return null; 
	else return new; end if; 
end; $$ language plpgsql; 

create trigger deletingTask
before delete on Tasks
for each row
execute procedure deleteTask(); 