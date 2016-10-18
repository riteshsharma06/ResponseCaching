//
//  ViewController.m
//  ResponseCaching
//
//  Created by SoftBunch  on 8/8/16.
//  Copyright © 2016 miimobileapp. All rights reserved.
//


#import "ViewController.h"

#import <AFNetworking/AFNetworking.h>

@interface ViewController ()<NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate,NSURLSessionDelegate>
{
    NSMutableArray *arrCities;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    arrCities = [[NSMutableArray alloc] init];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
        //AFNetworkReachabilityStatusUnknown
       // AFNetworkReachabilityStatusNotReachable
    }];    // Do any additional setup after loading the view, typically from a nib.
    [self getCityData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark tableview Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([arrCities count] > 0)
    {
        return [arrCities count];
    }
    else
    {
         return 0;
    }
  
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[self.myTableView dequeueReusableCellWithIdentifier:@"idCell"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",[arrCities objectAtIndex:indexPath.row]];
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}
#pragma mark

-(void)getCityData
{
    NSString *string = [NSString stringWithFormat:@"%@",@"Your Api URL"];
    NSURL *url = [NSURL URLWithString:string];
    NSDictionary *parameters = @{ @"paremeter name": @"parameter data"};
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url
                                                             sessionConfiguration:sessionConfiguration];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:string parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
            if(status == AFNetworkReachabilityStatusUnknown || status == AFNetworkReachabilityStatusNotReachable )
            {
               manager.requestSerializer.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
                NSLog(@"reponse object : %@",responseObject);
                
            }
        }];
        NSError *error;
        NSMutableDictionary *json =[NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        NSLog(@"responseObject = %@", json);
        if([[json objectForKey:@"status"] isEqualToString:@"1"])
        {
            arrCities = [json objectForKey:@"city_name"];
            [self.myTableView reloadData];
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"error = %@", error);
    }];
    [manager setDataTaskWillCacheResponseBlock:^NSCachedURLResponse * (NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse) {
        NSLog(@"Sending back a cached response");
        NSCachedURLResponse * responseCached;
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)[proposedResponse response];
        if (dataTask.originalRequest.cachePolicy == NSURLRequestUseProtocolCachePolicy) {
            NSDictionary *headers = httpResponse.allHeaderFields;
            NSString * cacheControl = [headers valueForKey:@"Cache-Control"];
            NSString * expires = [headers valueForKey:@"Expires"];
            if (cacheControl == nil && expires == nil) {
                NSLog(@"Server does not provide expiration information and use are using NSURLRequestUseProtocolCachePolicy");
                responseCached = [[NSCachedURLResponse alloc] initWithResponse:dataTask.response
                                                                          data:proposedResponse.data
                                                                      userInfo:@{ @"response" : dataTask.response, @"proposed" : proposedResponse.data }
                                                                 storagePolicy:NSURLCacheStorageAllowed];
            }
        }
        return responseCached;
    }];
}
@end
