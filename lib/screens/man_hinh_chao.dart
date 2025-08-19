import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';

class ManHinhChao extends StatefulWidget {
  const ManHinhChao({Key? key}) : super(key: key);

  @override
  State<ManHinhChao> createState() => _ManHinhChaoState();
}

class _ManHinhChaoState extends State<ManHinhChao> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MauSac.denNen,
              MauSac.denNhat,
              MauSac.denNen,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container với hiệu ứng
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              MauSac.kfcRed,
                              MauSac.kfcRed.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MauSac.kfcRed.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: MauSac.kfcRed.withOpacity(0.2),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 0.1,
                          child: const Center(
                            child: Text(
                              'KFC',
                              style: TextStyle(
                                color: MauSac.trang,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Tên thương hiệu
                      const Text(
                        'Kentucky Fried Chicken',
                        style: TextStyle(
                          color: MauSac.trang,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Slogan
                      Text(
                        'Finger Lickin\' Good!',
                        style: TextStyle(
                          color: MauSac.xam.withOpacity(0.8),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Loading indicator
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 3),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Column(
                            children: [
                              Container(
                                width: 200,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: MauSac.xam.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 200 * value,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            MauSac.kfcRed,
                                            MauSac.kfcRed.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Đang tải...',
                                style: TextStyle(
                                  color: MauSac.xam.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
