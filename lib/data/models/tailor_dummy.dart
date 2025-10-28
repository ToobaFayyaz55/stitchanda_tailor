import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';

// ✅ Project model for gallery section
class TailorProject {
  final String title;
  final String rating;
  final String price;
  final Color coverColor;

  TailorProject({
    required this.title,
    required this.rating,
    required this.price,
    required this.coverColor,
  });
}

// ✅ Full Tailor model with profile fields
class TailorUser {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String address;
  final String gender;
  final String experience;
  final String category;
  final List<String> skills;
  final List<TailorProject> projects;

  TailorUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.address,
    required this.gender,
    required this.experience,
    required this.category,
    required this.skills,
    required this.projects,
  });
}

// ✅ Dummy Logged-in Tailor Data
TailorUser currentTailor = TailorUser(
  name: "Laiba Majeed",
  email: "laiba@gmail.com",
  phone: "+92 345 6789123",
  role: "Tailor",
  address: "123 Main Street, Karachi",
  gender: "Female",
  experience: "5 years",
  category: "All",
  skills: [
    "Bridal",
    "Stitching",
    "Kurta Pajama",
    "Custom Dresses",
    "Fashion Trend",
    "Suit Alteration",
    "Tailoring",
  ],
  projects: [
    TailorProject(
      title: "Lehenga",
      rating: "4.8",
      price: "20K PKR",
      coverColor: AppColors.beige,
    ),
    TailorProject(
      title: "Men Formal",
      rating: "4.7",
      price: "15K PKR",
      coverColor: AppColors.caramel,
    ),
    TailorProject(
      title: "Denim Jacket",
      rating: "4.9",
      price: "5K PKR",
      coverColor: AppColors.chocolate,
    ),
    TailorProject(
      title: "Blazer Formal",
      rating: "4.5",
      price: "18K PKR",
      coverColor: AppColors.deepBrown,
    ),
  ],
);
