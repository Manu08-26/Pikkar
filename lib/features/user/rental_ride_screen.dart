import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class RentalRideScreen extends StatefulWidget {
  const RentalRideScreen({super.key});

  @override
  State<RentalRideScreen> createState() => _RentalRideScreenState();
}

class _RentalRideScreenState extends State<RentalRideScreen> {
  final AppTheme _appTheme = AppTheme();
  bool dropLocationSame = false;
  bool getDriver = false;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _appTheme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _appTheme.iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
                color: _appTheme.textColor,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            localizations.rentalRide,
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup Location
                  Text(
                    localizations.pickupLocation,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: _appTheme.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      localizations.enterPickupLocation,
                      style: TextStyle(
                        fontSize: 14,
                        color: _appTheme.textGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Drop Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.dropLocation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _appTheme.textColor,
                        ),
                      ),
                      Switch(
                        value: dropLocationSame,
                        onChanged: (value) {
                          setState(() {
                            dropLocationSame = value;
                          });
                        },
                        activeColor: _appTheme.brandRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle locate on map
                    },
                    icon: Icon(Icons.my_location, color: _appTheme.brandRed, size: 20),
                    label: Text(
                      localizations.locateOnMap,
                      style: TextStyle(
                        color: _appTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appTheme.iconBgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Time & Date
                  Text(
                    localizations.startTimeAndDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle select date
                          },
                          icon: Icon(Icons.calendar_today, color: _appTheme.textColor, size: 18),
                          label: Text(
                            localizations.selectDate,
                            style: TextStyle(
                              color: _appTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _appTheme.iconBgColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle select time
                          },
                          icon: Icon(Icons.access_time, color: _appTheme.textColor, size: 18),
                          label: Text(
                            localizations.selectTime,
                            style: TextStyle(
                              color: _appTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _appTheme.iconBgColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // End Time & Date
                  Text(
                    localizations.endTimeAndDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle select date
                          },
                          icon: Icon(Icons.calendar_today, color: _appTheme.textColor, size: 18),
                          label: Text(
                            localizations.selectDate,
                            style: TextStyle(
                              color: _appTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _appTheme.iconBgColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle select time
                          },
                          icon: Icon(Icons.access_time, color: _appTheme.textColor, size: 18),
                          label: Text(
                            localizations.selectTime,
                            style: TextStyle(
                              color: _appTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _appTheme.iconBgColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Get a Driver Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.getDriverForTrip,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _appTheme.brandRed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizations.noDriverYet,
                              style: TextStyle(
                                fontSize: 13,
                                color: _appTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: getDriver,
                        onChanged: (value) {
                          setState(() {
                            getDriver = value;
                          });
                        },
                        activeColor: _appTheme.brandRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Find Now Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _appTheme.cardColor,
              border: Border(
                top: BorderSide(color: _appTheme.dividerColor, width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appTheme.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.findNow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

