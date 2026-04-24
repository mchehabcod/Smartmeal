/// Simple grocery-aisle style buckets for US009 categorized shopping list.
String categorizeIngredient(String rawName) {
  final n = rawName.toLowerCase().trim();
  if (n.isEmpty) return 'Other';

  bool any(String keywords) {
    return keywords.split(' ').any((k) => k.isNotEmpty && n.contains(k));
  }

  if (any(
      'milk cheese yogurt butter cream egg mozzarella cheddar parmesan paneer')) {
    return 'Dairy & eggs';
  }
  if (any(
      'tomato onion garlic pepper lettuce spinach carrot potato broccoli cucumber '
      'cabbage kale zucchini mushroom apple banana orange lemon lime avocado')) {
    return 'Produce';
  }
  if (any(
      'chicken beef pork lamb turkey fish salmon tuna shrimp prawn sausage bacon mince')) {
    return 'Meat & seafood';
  }
  if (any(
      'rice pasta noodle bread flour tortilla oat sugar salt oil olive vinegar soy sauce')) {
    return 'Pantry & grains';
  }
  if (any('bean lentil chickpea tofu')) {
    return 'Plant protein';
  }
  return 'Other';
}
