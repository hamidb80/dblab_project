CREATE TABLE IF NOT EXISTS aircompany (
  id INT,
  name TEXT,

  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS airplane (
  id INT,
  company_id INT,
  
  PRIMARY KEY (id),
  FOREIGN KEY (company_id) REFERENCES aircompany (id) 
);

CREATE TABLE IF NOT EXISTS travel (
  id INT,
  airplane_id INT,
  pilot TEXT,
  destination TEXT,
  takeoff DATE,
    
  PRIMARY KEY (id),
  FOREIGN KEY airplane_id REFERENCES airplane (id) 
);

CREATE TABLE IF NOT EXISTS ticket (
  id INT,
  travel_id INT,
  seat INT,
    
  PRIMARY KEY (id),
  FOREIGN KEY travel_id REFERENCES travel (id) 
);