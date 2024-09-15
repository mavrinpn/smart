import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart/feature/home/bloc/scroll/scroll_cubit.dart';
import 'package:smart/feature/main/bloc/search/search_announcements_cubit.dart';
import 'package:smart/feature/main/ui/sections/categories_section.dart';
import 'package:smart/feature/main/ui/widgets/appbar_with_search_field.dart';
import 'package:smart/feature/main/ui/widgets/city_button.dart';
import 'package:smart/feature/search/bloc/select_subcategory/search_select_subcategory_cubit.dart';
import 'package:smart/feature/search/ui/bottom_sheets/filter_bottom_sheet_dialog.dart';
import 'package:smart/feature/search/ui/sections/popular_queries.dart';
import 'package:smart/localization/app_localizations.dart';
import 'package:smart/utils/constants.dart';
import 'package:smart/utils/routes/route_names.dart';
import 'package:smart/utils/utils.dart';
import 'package:smart/widgets/scaffold/main_scaffold.dart';

import '../../../managers/announcement_manager.dart';
import '../../../widgets/conatainers/advertisement_containers.dart';
import '../../../widgets/conatainers/announcement_container.dart';
import '../../search/bloc/search_announcement_cubit.dart';
import '../bloc/announcements/announcements_cubit.dart';
import '../bloc/popularQueries/popular_queries_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final searchController = TextEditingController();
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    BlocProvider.of<PopularQueriesCubit>(context).loadPopularQueries();
    _initScrollListener();
  }

  void _initScrollListener() {
    _controller.addListener(() async {
      final announcementRepository = RepositoryProvider.of<AnnouncementManager>(context);
      if (announcementRepository.recommendationAnnouncementsWithExactLocation.length +
              announcementRepository.recommendationAnnouncementsWithOtherLocation.length >
          0) {
        if (_controller.position.atEdge) {
          double maxScroll = _controller.position.maxScrollExtent;
          double currentScroll = _controller.position.pixels;
          if (currentScroll >= maxScroll * 0.8) {
            final searchCubit = BlocProvider.of<SearchAnnouncementCubit>(context);
            BlocProvider.of<AnnouncementsCubit>(context).loadAnnounces(
              false,
              cityId: searchCubit.cityId,
              areaId: searchCubit.areaId,
            );
          }
        }
      }
    });
  }

  bool isSearch = false;

  void setSearch(bool f) {
    setState(() {
      isSearch = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcementRepository = RepositoryProvider.of<AnnouncementManager>(context);

    void openSearchScreen({
      required String? query,
      required bool showKeyboard,
    }) {
      final subcategoriesCubit = context.read<SearchSelectSubcategoryCubit>();
      final searchCubit = context.read<SearchAnnouncementCubit>();
      searchCubit.setSubcategory(null);
      searchCubit.setSearchMode(SearchModeEnum.simple);

      subcategoriesCubit.getSubcategoryFilters('').then((value) => searchCubit.searchAnnounces(
            searchText: '',
            isNew: true,
            showLoading: true,
            parameters: [],
          ));

      BlocProvider.of<PopularQueriesCubit>(context).loadPopularQueries();
      // BlocProvider.of<SearchAnnouncementCubit>(context).searchAnnounces(
      //   searchText: '',
      //   isNew: true,
      //   showLoading: false,
      // );
      Navigator.pushNamed(
        context,
        AppRoutesNames.search,
        arguments: {
          'query': query,
          'backButton': false,
          'showKeyboard': showKeyboard,
        },
      ).then((value) {
        BlocProvider.of<SearchItemsCubit>(context).searchKeywords(
          query: '',
          subcategoryId: '',
        );
      });
    }

    void openFilters() {
      openSearchScreen(query: null, showKeyboard: false);
      context.read<SearchAnnouncementCubit>().setSearchMode(SearchModeEnum.simple);
      showFilterBottomSheet(context: context);
    }

    return BlocListener<ScrollCubit, ScrollState>(
      listener: (context, state) {
        if (state is ScrollToTop) {
          _controller.animateTo(
            0,
            duration: Durations.medium2,
            curve: Curves.bounceInOut,
          );
        }
      },
      child: MainScaffold(
        canPop: false,
        appBar: AppBar(
          backgroundColor: AppColors.appBarColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: MainAppBar(
            isSearch: isSearch,
            openSearchScreen: () => openSearchScreen(query: null, showKeyboard: true),
            openFilters: openFilters,
            cancel: () {
              FocusScope.of(context).unfocus();
              setSearch(false);
            },
          ),
        ),
        body: BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.red,
              onRefresh: () async {
                final searchCubit = BlocProvider.of<SearchAnnouncementCubit>(context);
                BlocProvider.of<AnnouncementsCubit>(context).loadAnnounces(
                  true,
                  cityId: searchCubit.cityId,
                  areaId: searchCubit.areaId,
                );
              },
              child: CustomScrollView(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  //TODO test map
                  // SliverToBoxAdapter(
                  //   child: SizedBox(
                  //     height: 300,
                  //     child: CommonMap().buildMap(
                  //       myLocationEnabled: true,
                  //       myLocationButtonEnabled: true,
                  //       zoomControlsEnabled: true,
                  //       initial: CommonLatLng(51.507220, -0.127500),
                  //       markers: {
                  //         CommonLatLng(51.507220, -0.127500),
                  //       },
                  //     ),
                  //   ),
                  // ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: PopularQueriesWidget(
                        onSearch: (e) {
                          openSearchScreen(query: e, showKeyboard: false);
                        },
                      ),
                    ),
                  ),
                  const CategoriesSection(),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                  SliverToBoxAdapter(
                    child: AdvertisementContainer(
                      onTap: () {},
                      imageUrl:
                          '$serviceProtocol$serviceDomain/v1/storage/buckets/661d74e7000bc76c563f/files/main_ad/view?project=65d8fa703a95c4ef256b&mode=admin',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.recommendations,
                            textAlign: TextAlign.center,
                            style: AppTypography.font20black,
                          ),
                          const CityButton(),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.anouncementGridSidePadding,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        crossAxisSpacing: AppSizes.anouncementGridCrossSpacing,
                        mainAxisSpacing: AppSizes.anouncementGridMainSpacing,
                        maxCrossAxisExtent: MediaQuery.of(context).size.width / 2,
                        childAspectRatio: AppSizes.anouncementAspectRatio(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => AnnouncementContainer(
                            announcement: announcementRepository.recommendationAnnouncementsWithExactLocation[index]),
                        childCount: announcementRepository.recommendationAnnouncementsWithExactLocation.length,
                        // childCount: announcementRepository.recommendationAnnouncements.length % 2 == 0
                        //     ? announcementRepository.recommendationAnnouncements.length
                        //     : announcementRepository.recommendationAnnouncements.length - 1,
                      ),
                    ),
                  ),
                  if (announcementRepository.recommendationAnnouncementsWithOtherLocation.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.anouncementGridSidePadding,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset('Assets/search_other_city.jpg'),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.otherCity,
                              style: AppTypography.font20black,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.anouncementGridSidePadding,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        crossAxisSpacing: AppSizes.anouncementGridCrossSpacing,
                        mainAxisSpacing: AppSizes.anouncementGridMainSpacing,
                        maxCrossAxisExtent: MediaQuery.of(context).size.width / 2,
                        childAspectRatio: AppSizes.anouncementAspectRatio(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => AnnouncementContainer(
                            announcement: announcementRepository.recommendationAnnouncementsWithOtherLocation[index]),
                        childCount: announcementRepository.recommendationAnnouncementsWithOtherLocation.length % 2 == 0
                            ? announcementRepository.recommendationAnnouncementsWithOtherLocation.length
                            : announcementRepository.recommendationAnnouncementsWithOtherLocation.length - 1,
                      ),
                    ),
                  ),
                  if (announcementRepository.recommendationAnnouncementsWithExactLocation.length +
                          announcementRepository.recommendationAnnouncementsWithOtherLocation.length >=
                      20)
                    SliverToBoxAdapter(
                      child: Center(
                        child: SizedBox(
                          height: 200,
                          child: AppAnimations.bouncingLine,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
