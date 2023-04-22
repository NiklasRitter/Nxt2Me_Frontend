import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/event_detail_page.dart';
import 'package:event_app/src/utility/formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class ExploreElement extends StatefulWidget {
  /// Card to show brief overview over event
  const ExploreElement({Key? key, required this.event, required this.callback})
      : super(key: key);

  final Event event;

  // used to refresh ancestor page if changes on event are made
  final Future Function() callback;

  @override
  _ExploreElementState createState() => _ExploreElementState();
}

class _ExploreElementState extends State<ExploreElement> {
  final exploreElementKey = GlobalKey<_ExploreElementState>();

  late Event event;
  late bool toggleButtonFavourite;
  late String schedule;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    if (mounted) {
      setState(() {
        toggleButtonFavourite =
            appState.user.favoriteEventIds.contains(event.eventId);
        likeCount = widget.event.likeCount;
      });
    }

    schedule = Formatter.getDateFormatted(event.startTimestamp, 'dd. MMMM ') +
        Formatter.getTimeFormatted(event.startTimestamp) +
        ' - ' +
        Formatter.getDateFormatted(event.endTimestamp, 'dd. MMMM ') +
        Formatter.getTimeFormatted(event.endTimestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Constants.backgroundColorSecondary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () async {
            // route to detailsPage of event
            await Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.fade,
                  duration: const Duration(milliseconds: 250),
                  reverseDuration: const Duration(milliseconds: 250),
                  child: EventDetailsPage(key: exploreElementKey, event: event),
                  fullscreenDialog: true,
                )).then((updatedEvent) async {
              if (mounted) {
                if (updatedEvent != null) {
                  setState(() {
                    // set new details of event
                    event = updatedEvent;
                  });
                }
                setState(() {
                  // actualize like count
                  toggleButtonFavourite =
                      appState.user.favoriteEventIds.contains(event.eventId);
                  likeCount = widget.event.likeCount;
                });
              }
              // refresh widget in ancestor widget
              await widget.callback();
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 0.75,
                child: Stack(
                  children: [
                    Align(
                        alignment: Alignment.topCenter,
                        child: event.image == null
                            ? Image(
                                image: Image.asset('assets/images/Stand_By.jpg')
                                    .image,
                                colorBlendMode: BlendMode.color,
                              )
                            : CachedNetworkImage(
                                imageUrl: event.image!,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(
                                  color: Constants.themeColor,
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
                        child: Card(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          color: Constants.backgroundColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                8, 8, 8, 8),
                            child: InkResponse(
                              radius: 25,
                              // like or dislike event
                              onTap: () async {
                                if (appState.offlineMode == true ||
                                    appState.serverAlive == false) return;

                                int newValue = -1;

                                try {
                                  newValue = await network.toggleFavoriteEvent(
                                      widget.event.eventId);
                                } catch (e) {
                                  if (kDebugMode) {
                                    print(
                                        'Fav toggle not possible because of unreachable network or server!');
                                  }
                                  return;
                                }

                                if (newValue != -1) {
                                  toggleButtonFavourite =
                                      !toggleButtonFavourite;

                                  // add or remove favorite
                                  if (toggleButtonFavourite) {
                                    appState.user.favoriteEventIds
                                        .add(widget.event.eventId);
                                  } else {
                                    appState.user.favoriteEventIds
                                        .remove(widget.event.eventId);
                                  }

                                  // set current likeCount
                                  widget.event.likeCount = newValue;
                                  await appState.sqliteDbUsers
                                      .updateUser(appState.user);
                                  await appState.sqliteDbEvents
                                      .updateEvent(widget.event);
                                  likeCount = widget.event.likeCount;
                                  toggleButtonFavourite = toggleButtonFavourite;
                                  // refresh ancestor widget
                                  await widget.callback();
                                }
                              },
                              child: Icon(
                                toggleButtonFavourite
                                    ? Icons.star_rate
                                    : Icons.star_outline,
                                color: Constants.iconColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          physics: const ScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            event.category.toString(),
                            style: const MyTextStyle(
                              cColor: Constants.themeColor,
                              cFontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(10, 0, 0, 0),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                            child: Icon(Icons.thumb_up_alt_rounded,
                                color: Constants.themeColor),
                          ),
                          Text(
                            likeCount.toString(),
                            style: const MyTextStyle(
                              cColor: Colors.black,
                              cFontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 1,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBE2E7),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Text(
                        event.eventName,
                        style: const MyTextStyle(
                          cColor: Constants.mainTextColorDark,
                          cFontSize: 18,
                          cFontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Text(
                        event.description,
                        style: const MyTextStyle(
                          cColor: Constants.secondaryTextColorDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Constants.themeColor,
                              size: 20,
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  4, 0, 0, 0),
                              child: Text(
                                schedule,
                                style: const MyTextStyle(
                                  cColor: Constants.themeColor,
                                  cFontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_sharp,
                                color: Constants.themeColor,
                                size: 20,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    4, 0, 0, 0),
                                child: Text(
                                  event.locationName,
                                  style: const MyTextStyle(
                                    cColor: Constants.themeColor,
                                    cFontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ]),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
