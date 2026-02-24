import 'package:flutter/material.dart';

class SmoothCardScroll extends StatefulWidget {
  const SmoothCardScroll({super.key});

  @override
  State<SmoothCardScroll> createState() => _SmoothCardScrollState();
}

class _SmoothCardScrollState extends State<SmoothCardScroll> {

  final PageController controller =
      PageController(viewportFraction: 0.65);

  final List<String> images = [
    "https://images.unsplash.com/photo-1544025162-d76694265947",
    "https://images.unsplash.com/photo-1558030006-450675393462",
    "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
    "https://images.unsplash.com/photo-1547592180-85f173990554",
    "https://images.unsplash.com/photo-1551024709-8f23befc6f87",
  ];

  double currentPage = 0;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      setState(() {
        currentPage = controller.page!;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ================= CARD BUILDER =================

  Widget buildCard(int index) {

    double diff = (currentPage - index);
    double scale = 1 - (diff.abs() * 0.15);
    scale = scale.clamp(0.8, 1.0);

    double translateX = diff * 40;

    return Transform.translate(
      offset: Offset(-translateX, 0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE6E1D8),

      body: SafeArea(
        child: PageView.builder(
          controller: controller,
          scrollDirection: Axis.vertical,
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Align(
              alignment: Alignment.centerRight, // posisi agak ke kanan
              child: SizedBox(
                height: 320,
                child: buildCard(index),
              ),
            );
          },
        ),
      ),
    );
  }
}
