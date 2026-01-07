const bcrypt = require("bcrypt");
bcrypt.compare("123456", "$2b$10$8Olv1ZQ3MOCa/44hsGnej.AgAUxL.8pVLBhfOCqF6f3RM.2k4B5Zy").then(console.log);
