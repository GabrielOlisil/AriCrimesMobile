class AuthUser {
  String? name;
  String? preferredUsername;
  String? givenName;
  String? familyName;
  String? email;
  String? picture;

  AuthUser();

  AuthUser.init(
    this.name,
    this.preferredUsername,
    this.givenName,
    this.familyName,
    this.email,
    this.picture,
  );

  @override
  String toString() {
    return "Nome: $name\n"
        "preferred username: $preferredUsername\n"
        "given name: $givenName\n"
        "family name: $familyName\n"
        "email: $email\n"
        "picture: $picture\n";
  }
}
