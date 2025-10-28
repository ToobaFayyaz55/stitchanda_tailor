// lib/data/dummy_user.dart

class TailorUser {
  final String email;
  final String username;
  final String fullName;
  final String phone;
  final String role;
  final String address;
  final String experience;
  final List<String> skills;

  const TailorUser({
    required this.email,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.address,
    required this.experience,
    required this.skills,
  });
}

const dummyTailor = TailorUser(
  email: "laiba@gmail.com",
  username: "laiba",
  fullName: "Laiba Majeed",
  phone: "+92 300 1234567",
  role: "Tailor",
  address: "North Karachi, Pakistan",
  experience: "5 years",
  skills: [
    "Bridal",
    "Stitching",
    "Alteration",
  ],
);
