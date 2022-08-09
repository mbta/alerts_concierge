use rand::Rng;
use regex::Regex;

fn mock_email() -> String {
	let address: String = rand::thread_rng()
		.sample_iter(&rand::distributions::Alphanumeric)
		.take(10)
		.map(char::from)
		.collect();

	format!("{}@test.com", address)
}

fn main() {
	let email_sql =
		Regex::new(r###"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\t"###)
			.unwrap();

	let email_phone_sql = Regex::new(
		r###"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\t[0-9]{10}\b"###,
	)
	.unwrap();

	let email_json = Regex::new(
		r###""email": "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+""###,
	)
	.unwrap();

	let subscriber_email_json = Regex::new(
		r###""subscriber_email": "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+""###,
	)
	.unwrap();

	let phone_number_json =
		Regex::new(r###""phone_number": "[0-9]{10}""###).unwrap();

	let stdin = std::io::stdin();
	let lines = stdin.lines();

	for l in lines {
		let email = mock_email();
		let l = l.unwrap();

		let l = email_sql
			.replace_all(&l, |_: &regex::Captures| format!("{}\t", email));

		let l = email_phone_sql.replace_all(&l, |_: &regex::Captures| {
			format!("{}\t{}\t", email, "5555555555",)
		});

		let l = email_json.replace_all(&l, |_: &regex::Captures| {
			format!(r###""email": "{}""###, email)
		});

		let l = subscriber_email_json.replace_all(&l, |_: &regex::Captures| {
			format!(r###""subscriber_email": "{}""###, email)
		});

		let l = phone_number_json.replace_all(
			&l,
			|_: &regex::Captures| r###""phone_number": "5555555555""###,
		);

		println!("{}", l);
	}
}
