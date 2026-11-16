import '../models/models.dart';

const List<String> kFoodCategories = [
  'Protein',
  'Rice & Carbs',
  'Canned & Processed',
  'Ulam',
  'Fruits & Veg',
  'Snacks & Drinks',
];

/// Estimates for a typical serving. Brands and cooking oil change the numbers,
/// so check the label of the product you actually eat. Edit or add rows freely.
///
/// Food(name, searchWords, category, serving, kcal, protein g, carbs g, fat g, note)
const List<Food> kFoods = [
  // ---------------- PROTEIN ----------------
  Food('Itlog, nilaga', 'egg boiled hard boiled', 'Protein', '1 large egg (50 g)', 78, 6.3, 0.6, 5.3),
  Food('Itlog, prito', 'egg fried sunny side', 'Protein', '1 egg, fried in oil', 90, 6.3, 0.4, 7),
  Food('Itlog na maalat', 'salted egg duck egg itlog na pula', 'Protein', '1 salted duck egg (~70 g)', 130, 9, 1, 10, 'Very salty'),
  Food('Chicken breast', 'manok dibdib grilled boiled inihaw', 'Protein', '100 g cooked, no skin', 165, 31, 0, 3.6, 'Best protein per calorie'),
  Food('Chicken thigh', 'manok hita grilled', 'Protein', '100 g cooked, no skin', 179, 25, 0, 8),
  Food('Chicken adobo', 'manok adobo', 'Protein', '1 serving (~150 g)', 280, 24, 4, 18, 'Skin, oil and sauce raise the calories'),
  Food('Fried chicken drumstick', 'pritong manok chicken joy', 'Protein', '1 piece (~100 g)', 250, 20, 8, 15, 'Breaded and fried'),
  Food('Tinolang manok', 'tinola chicken soup', 'Protein', '1 bowl (~250 g)', 190, 20, 6, 9),
  Food('Bangus, inihaw', 'milkfish grilled steamed isda', 'Protein', '100 g cooked', 150, 21, 0, 7),
  Food('Tilapia, steamed', 'tilapia grilled isda fish', 'Protein', '100 g cooked', 128, 26, 0, 2.7, 'Lean and cheap'),
  Food('Galunggong, prito', 'round scad fried isda fish', 'Protein', '1 medium fish (~80 g)', 150, 18, 0, 8.5),
  Food('Tuyo', 'dried fish daing isda', 'Protein', '30 g', 90, 14, 0, 3.5, 'Very salty'),
  Food('Hipon, nilaga', 'shrimp boiled prawn', 'Protein', '100 g cooked', 99, 24, 0.2, 0.3),
  Food('Tokwa', 'tofu bean curd', 'Protein', '100 g', 80, 8, 2, 4.8, 'Fried tokwa has much more fat'),
  Food('Pork chop, grilled', 'baboy pork liempo lean inihaw', 'Protein', '100 g cooked, lean', 220, 27, 0, 12),
  Food('Beef tapa', 'tapsilog beef cured', 'Protein', '100 g cooked', 210, 26, 5, 9, 'Cured, so salty'),
  Food('Whey protein', 'protein shake powder supplement', 'Protein', '1 scoop (30 g)', 120, 24, 3, 1.5, 'Varies by brand'),

  // ---------------- RICE & CARBS ----------------
  Food('Kanin (white rice)', 'rice steamed rice', 'Rice & Carbs', '1 cup cooked (158 g)', 205, 4.3, 45, 0.4),
  Food('Sinangag', 'garlic fried rice', 'Rice & Carbs', '1 cup', 260, 5, 46, 6),
  Food('Brown rice', 'kanin brown', 'Rice & Carbs', '1 cup cooked', 216, 5, 45, 1.8, 'More fiber than white rice'),
  Food('Pandesal', 'bread roll tinapay', 'Rice & Carbs', '1 piece (~40 g)', 120, 3.5, 22, 2),
  Food('Loaf bread', 'tasty bread sliced tinapay', 'Rice & Carbs', '1 slice (~28 g)', 75, 2.5, 14, 1),
  Food('Oatmeal', 'oats cooked in water', 'Rice & Carbs', '1 cup cooked', 150, 6, 27, 3, 'Without sugar or milk'),
  Food('Kamote, nilaga', 'sweet potato boiled camote', 'Rice & Carbs', '150 g', 115, 2.1, 26.5, 0.2),
  Food('Mais, nilaga', 'corn boiled cob', 'Rice & Carbs', '1 medium cob', 110, 3.4, 22, 1.3),

  // ---------------- CANNED & PROCESSED ----------------
  Food('Sardinas (tomato sauce)', 'sardines canned ligo mega', 'Canned & Processed', '1 can (155 g)', 220, 20, 6, 12, 'High sodium'),
  Food('Corned beef', 'canned purefoods delimondo', 'Canned & Processed', '100 g', 210, 14, 3, 15, 'High fat and sodium'),
  Food('Tuna flakes in water', 'canned tuna century', 'Canned & Processed', '1 can (~100 g drained)', 110, 25, 0, 1, 'Great gym food'),
  Food('Tuna flakes in oil', 'canned tuna century', 'Canned & Processed', '1 can (~100 g drained)', 190, 24, 0, 10),
  Food('Luncheon meat', 'spam tulip', 'Canned & Processed', '2 slices (~56 g)', 170, 7, 2, 15, 'High sodium'),
  Food('Hotdog', 'tender juicy hot dog', 'Canned & Processed', '1 piece (~50 g)', 150, 5, 3, 13),
  Food('Longganisa', 'sausage hamonado skinless', 'Canned & Processed', '1 link (~50 g)', 170, 8, 9, 11),
  Food('Tocino', 'sweet cured pork tosilog', 'Canned & Processed', '3 pieces (~100 g)', 250, 14, 20, 12, 'Sweet cured, with added sugar'),
  Food('Pancit Canton (instant)', 'instant noodles lucky me', 'Canned & Processed', '1 pack (80 g)', 360, 8, 50, 14, 'High sodium'),
  Food('Cup noodles', 'instant noodles nissin', 'Canned & Processed', '1 cup (~60 g)', 280, 6, 38, 12, 'High sodium'),
  Food('Crackers (Skyflakes)', 'biscuit cracker', 'Canned & Processed', '1 pack (~25 g)', 110, 2, 18, 3),

  // ---------------- ULAM ----------------
  Food('Sinigang na baboy', 'pork sour soup', 'Ulam', '1 bowl (~300 g)', 250, 18, 10, 15),
  Food('Pork adobo', 'baboy adobo', 'Ulam', '1 serving (~150 g)', 330, 25, 4, 24, 'High fat'),
  Food('Pancit bihon', 'noodles stir fried', 'Ulam', '1 cup (~200 g)', 250, 8, 35, 8),
  Food('Lumpiang shanghai', 'spring rolls fried', 'Ulam', '3 pieces', 200, 8, 18, 11),
  Food('Ginisang monggo', 'mung bean stew munggo', 'Ulam', '1 cup', 200, 12, 30, 4, 'Good plant protein and fiber'),
  Food('Pinakbet', 'mixed vegetables bagoong', 'Ulam', '1 cup', 100, 4, 12, 4),
  Food('Chopsuey', 'chop suey vegetables', 'Ulam', '1 cup', 120, 7, 10, 6),

  // ---------------- FRUITS & VEG ----------------
  Food('Saging na saba', 'banana boiled cooking banana', 'Fruits & Veg', '1 piece (~100 g)', 115, 1, 28, 0.2),
  Food('Saging na lakatan', 'banana', 'Fruits & Veg', '1 piece (~100 g)', 90, 1, 22, 0.3, 'Good pre-workout snack'),
  Food('Mangga (hinog)', 'mango ripe', 'Fruits & Veg', '1 cup sliced (~165 g)', 100, 1.4, 25, 0.6),
  Food('Papaya', 'hinog ripe', 'Fruits & Veg', '1 cup cubes (~145 g)', 62, 0.7, 15.7, 0.4),
  Food('Pakwan', 'watermelon', 'Fruits & Veg', '1 cup (~150 g)', 46, 0.9, 11.5, 0.2),
  Food('Pinya', 'pineapple', 'Fruits & Veg', '1 cup chunks (~165 g)', 82, 0.9, 21.6, 0.2),
  Food('Abokado', 'avocado', 'Fruits & Veg', 'half medium (~100 g)', 160, 2, 9, 15, 'Healthy fats'),
  Food('Kangkong, luto', 'water spinach cooked', 'Fruits & Veg', '1 cup cooked', 25, 2.5, 3.5, 0.3),

  // ---------------- SNACKS & DRINKS ----------------
  Food('Gatas (full cream)', 'milk', 'Snacks & Drinks', '1 cup (240 ml)', 150, 8, 12, 8),
  Food('Gatas (low fat)', 'milk', 'Snacks & Drinks', '1 cup (240 ml)', 100, 8, 12, 2.5),
  Food('Buko juice', 'coconut water', 'Snacks & Drinks', '1 cup (240 ml)', 46, 1.7, 8.9, 0.5),
  Food('Softdrink', 'soda coke sprite royal', 'Snacks & Drinks', '1 can (330 ml)', 140, 0, 36, 0, 'Sugar only'),
  Food('Coffee 3-in-1', 'kape nescafe sachet', 'Snacks & Drinks', '1 sachet (~20 g)', 80, 1, 15, 2),
  Food('Peanut butter', 'mani spread', 'Snacks & Drinks', '1 tbsp (16 g)', 94, 3.6, 3.2, 8),
  Food('Mani (peanuts)', 'peanuts roasted nuts', 'Snacks & Drinks', 'small handful (28 g)', 161, 7, 5, 14),
  Food('Chicharon', 'pork rinds', 'Snacks & Drinks', '30 g', 160, 15, 0, 10),
  Food('Turon', 'banana lumpia fried', 'Snacks & Drinks', '1 piece', 230, 2, 38, 8),
];

/// Used by the Food tab. Matches the name or the extra search words.
List<Food> searchFoods(
  String query, {
  String category = 'All',
  bool proteinFirst = false,
}) {
  final q = query.trim().toLowerCase();
  final results = kFoods.where((f) {
    final inCategory = category == 'All' || f.category == category;
    final matches = q.isEmpty ||
        f.name.toLowerCase().contains(q) ||
        f.alt.toLowerCase().contains(q);
    return inCategory && matches;
  }).toList();
  if (proteinFirst) {
    results.sort((a, b) => b.protein.compareTo(a.protein));
  }
  return results;
}
